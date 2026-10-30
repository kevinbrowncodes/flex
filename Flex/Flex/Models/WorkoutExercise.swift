import Foundation
import SwiftData

@Model
class WorkoutExercise: Identifiable {
    var id = UUID()
    var order: Int = 0
    @Relationship(deleteRule: .nullify, inverse: \Exercise.workoutExercises)
    var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutExercise)
    var sets: [ExerciseSet]?
    var workout: Workout?

    /// Creates a workout exercise with a single empty set.
    convenience init(exercise: Exercise) {
        self.init(exercise: exercise, sets: [ExerciseSet(setNumber: 1)])
    }

    /// Creates a workout exercise with the given sets (no default set is added).
    init(exercise: Exercise, sets: [ExerciseSet], order: Int = 0) {
        self.exercise = exercise
        self.sets = sets
        self.order = order
    }

    // Computed property for safer access
    var setsArray: [ExerciseSet] {
        get { sets ?? [] }
        set { sets = newValue }
    }

    /// Sets ordered by set number.
    var orderedSets: [ExerciseSet] {
        (sets ?? []).sorted { $0.setNumber < $1.setNumber }
    }

    /// The heaviest weight logged in any set, if any.
    var bestWeight: Double? {
        (sets ?? []).compactMap { $0.weight }.max()
    }

    /// The set with the heaviest weight (ties broken by reps), if any set has a weight.
    var bestSet: ExerciseSet? {
        (sets ?? [])
            .filter { $0.weight != nil }
            .max { lhs, rhs in
                if lhs.weight != rhs.weight { return (lhs.weight ?? 0) < (rhs.weight ?? 0) }
                return (lhs.reps ?? 0) < (rhs.reps ?? 0)
            }
    }
}

@Model
class ExerciseSet: Identifiable {
    var id = UUID()
    var setNumber: Int = 1
    var reps: Int?
    var weight: Double?
    var time: String?
    var distance: Double?
    var isCompleted: Bool = false
    var workoutExercise: WorkoutExercise?

    init(setNumber: Int, reps: Int? = nil, weight: Double? = nil, time: String? = nil, distance: Double? = nil) {
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.time = time
        self.distance = distance
    }

    /// True when nothing has been logged for this set.
    var isEmpty: Bool {
        weight == nil && reps == nil && (time ?? "").isEmpty && distance == nil
    }

    /// Volume for this set: weight × reps. A set with a weight but no reps counts the weight once.
    var volume: Double {
        guard let weight, weight > 0 else { return 0 }
        return weight * Double(max(reps ?? 1, 0))
    }
}
