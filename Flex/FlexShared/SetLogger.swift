import Foundation

/// An exercise as Siri can name it: what a device's catalog knows about it (STORY_010). Identity
/// is the normalized name, as everywhere else between the devices.
struct CatalogExercise: Equatable, Hashable, Sendable, Identifiable {
    var name: String
    var bodyPart: String
    var category: String
    var barType: BarType?

    var id: String { ExerciseName.normalized(name) }

    init(name: String, bodyPart: String, category: String = "Strength", barType: BarType? = nil) {
        self.name = name
        self.bodyPart = bodyPart
        self.category = category
        self.barType = barType
    }
}

/// How a catalog orders what Siri may mean (STORY_010): exercises in the live workout first, then
/// the rest, each group by name; duplicates (the same exercise in two templates) once.
enum CatalogRanking {
    static func rank(_ exercises: [CatalogExercise], matching query: String, inWorkout: Set<String>) -> [CatalogExercise] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let matching = exercises.filter { exercise in
            guard needle.isEmpty || exercise.name.localizedCaseInsensitiveContains(needle) else { return false }
            return seen.insert(exercise.id).inserted
        }
        return matching.sorted { lhs, rhs in
            let lhsIn = inWorkout.contains(lhs.id)
            let rhsIn = inWorkout.contains(rhs.id)
            if lhsIn != rhsIn { return lhsIn }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

/// What "I did 135 for 8 on bench press" does to a live workout, as pure edits plus the sentence
/// Siri says (STORY_010). The intent applies the edits to the device's session.
enum SetLogger {
    struct Result: Equatable {
        /// The workout after the edits.
        var workout: LiveWorkout
        /// The edits to apply to a running session, in order. Empty when a workout was started: the
        /// result's workout is then the one to start with.
        var edits: [LiveWorkoutEdit]
        var startedWorkout: Bool
        var sentence: String
    }

    static func log(exercise: CatalogExercise, weight: Double, reps: Int, into existing: LiveWorkout?, restSeconds: TimeInterval, at now: Date = Date()) -> Result {
        var workout = existing ?? LiveWorkout(startedAt: now, restSeconds: restSeconds)
        let startedWorkout = existing == nil
        var edits: [LiveWorkoutEdit] = []
        func apply(_ edit: LiveWorkoutEdit) {
            workout.apply(edit, at: now)
            edits.append(edit)
        }

        // The exercise in this workout, added when it is not there yet.
        var target = workout.exercises.first { ExerciseName.normalized($0.name) == exercise.id }
        if target == nil {
            let added = LiveExercise(name: exercise.name, bodyPart: exercise.bodyPart, category: exercise.category, barType: exercise.barType, sets: [LiveSet()])
            apply(.addExercise(added))
            target = workout.exercise(withID: added.id)
        }
        guard var live = target else {
            return Result(workout: workout, edits: edits, startedWorkout: startedWorkout, sentence: "I couldn't log that set.")
        }

        // The first set not yet done, or a new one when every set is done.
        if !live.sets.contains(where: { !$0.isCompleted }) {
            apply(.addSet(exerciseID: live.id, set: LiveSet()))
            live = workout.exercise(withID: live.id) ?? live
        }
        guard let set = live.sets.first(where: { !$0.isCompleted }) else {
            return Result(workout: workout, edits: edits, startedWorkout: startedWorkout, sentence: "I couldn't log that set.")
        }
        apply(.setWeight(setID: set.id, weight: max(0, weight)))
        apply(.setReps(setID: set.id, reps: max(0, reps)))
        apply(.setCompleted(setID: set.id, isCompleted: true))

        let summary = Formatting.setSummary(weight: max(0, weight), reps: max(0, reps)) ?? "\(max(0, reps)) reps"
        let sentence = startedWorkout
            ? "Started \(workout.title) and logged \(summary) on \(exercise.name)."
            : "Logged \(summary) on \(exercise.name)."
        return Result(workout: workout, edits: startedWorkout ? [] : edits, startedWorkout: startedWorkout, sentence: sentence)
    }
}
