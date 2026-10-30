import Foundation
import SwiftData

/// Where the live workout meets SwiftData: starting one from a template with each exercise's
/// history, and saving a finished one as a `Workout`. The phone is the only device that touches
/// SwiftData; a watch only ever holds `LiveWorkout` values (EPIC_001, STORY_002).
@MainActor
enum LiveWorkoutBridge {
    /// A live workout from a template (or an empty one), with the template's sets and each
    /// exercise's most recent earlier performance for the "Previous" column.
    static func start(from template: WorkoutTemplate?, at start: Date = Date()) -> LiveWorkout {
        guard let template else {
            return LiveWorkout(startedAt: start)
        }
        let exercises = template.templateExercisesArray
            .sorted { $0.order < $1.order }
            .compactMap { templateExercise -> LiveExercise? in
                guard let exercise = templateExercise.exercise else { return nil }
                let templateSets = templateExercise.setsArray.sorted { $0.setNumber < $1.setNumber }
                let sets = templateSets.isEmpty
                    ? [LiveSet()]
                    : templateSets.map { LiveSet(reps: $0.reps, weight: $0.weight) }
                return liveExercise(for: exercise, sets: sets, before: start)
            }
        return LiveWorkout(title: template.name, startedAt: start, templateName: template.name, exercises: exercises)
    }

    /// A live exercise for a library exercise, carrying its most recent earlier performance.
    static func liveExercise(for exercise: Exercise, sets: [LiveSet] = [LiveSet()], before date: Date) -> LiveExercise {
        let previous = exercise.mostRecentWorkoutExercise(before: date)?.orderedSets.map { set in
            LiveSet(reps: set.reps, weight: set.weight, time: set.time, distance: set.distance, isCompleted: set.isCompleted)
        } ?? []
        return LiveExercise(
            name: exercise.name,
            bodyPart: exercise.bodyPart,
            category: exercise.category,
            barType: exercise.barType,
            sets: sets,
            previousSets: previous
        )
    }

    /// Saves a finished workout as a `Workout` with the live workout's id. Exercises are matched
    /// by `ExerciseName.normalized` against every exercise, archived included, or created as
    /// custom exercises. A finished workout whose id is already saved returns the saved one, so
    /// a second delivery (a watch retrying, say) saves nothing twice.
    @discardableResult
    static func save(_ finished: FinishedWorkout, into context: ModelContext) throws -> Workout {
        let id = finished.workout.id
        let already = try context.fetch(FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id }))
        if let saved = already.first {
            return saved
        }

        let groups = Dictionary(grouping: try context.fetch(FetchDescriptor<Exercise>())) { ExerciseName.normalized($0.name) }
        var byName = groups.mapValues { ExerciseLibrary.preferredKeeper(among: $0) }

        var workoutExercises: [WorkoutExercise] = []
        for (order, live) in finished.workout.exercises.enumerated() {
            let key = ExerciseName.normalized(live.name)
            let exercise: Exercise
            if let known = byName[key] {
                exercise = known
            } else {
                exercise = Exercise(name: live.name, bodyPart: live.bodyPart, category: live.category, barType: live.barType)
                context.insert(exercise)
                byName[key] = exercise
            }
            let sets = live.sets.enumerated().map { index, set -> ExerciseSet in
                let saved = ExerciseSet(setNumber: index + 1, reps: set.reps, weight: set.weight, time: set.time, distance: set.distance)
                saved.isCompleted = set.isCompleted
                return saved
            }
            workoutExercises.append(WorkoutExercise(exercise: exercise, sets: sets, order: order))
        }

        let workout = Workout(
            title: finished.workout.title,
            date: finished.workout.startedAt,
            duration: finished.duration,
            exercises: workoutExercises
        )
        workout.id = id
        context.insert(workout)
        try context.save()
        return workout
    }
}
