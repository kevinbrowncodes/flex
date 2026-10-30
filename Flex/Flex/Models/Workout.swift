import Foundation
import SwiftData

@Model
class Workout: Identifiable {
    var id = UUID()
    var title: String = ""
    var date: Date = Date()
    var duration: TimeInterval = 0
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]?

    /// Exercises in the order they were added (SwiftData does not preserve array order across saves).
    var orderedExercises: [WorkoutExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    /// Total volume lifted in this workout (weight × reps, summed over every set).
    var totalVolume: Double {
        Workout.volume(of: exercises ?? [])
    }

    /// Volume for an arbitrary collection of exercises (used before a workout is saved).
    static func volume(of exercises: [WorkoutExercise]) -> Double {
        exercises
            .flatMap { $0.sets ?? [] }
            .reduce(0) { $0 + $1.volume }
    }

    /// Number of personal records in this workout.
    ///
    /// A PR is counted for an exercise when the heaviest set in this workout is heavier than the
    /// heaviest set of that exercise in every earlier workout (including the first time it is performed).
    func calculatePRCount(comparedTo allWorkouts: [Workout]) -> Int {
        let previousWorkouts = allWorkouts.filter { $0.id != id && $0.date < date }
        var prCount = 0

        for workoutExercise in exercises ?? [] {
            guard let exercise = workoutExercise.exercise,
                  let bestWeight = workoutExercise.bestWeight,
                  bestWeight > 0 else { continue }

            let previousBest = previousWorkouts
                .flatMap { $0.exercises ?? [] }
                .filter { $0.exercise?.persistentModelID == exercise.persistentModelID }
                .compactMap { $0.bestWeight }
                .max() ?? 0

            if bestWeight > previousBest {
                prCount += 1
            }
        }

        return prCount
    }

    init(title: String, date: Date, duration: TimeInterval, exercises: [WorkoutExercise]) {
        self.title = title
        self.date = date
        self.duration = duration
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
        }
        self.exercises = exercises
    }
}
