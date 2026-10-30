import SwiftUI
import SwiftData

/// One exercise inside a saved workout being edited: the set table over SwiftData models.
/// A workout in progress uses `LiveExerciseSetView` instead (STORY_002).
struct ExerciseSetView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workoutExercise: WorkoutExercise
    @Binding var showNumberPicker: Bool
    @Binding var numberPickerType: NumberPickerType
    @Binding var selectedNumber: Binding<Double?>?
    @Binding var currentExerciseName: String?
    @Binding var currentBarType: BarType?
    var onRemove: () -> Void

    private var exerciseName: String {
        workoutExercise.exercise?.name ?? "Unknown Exercise"
    }

    /// Sets from the most recent earlier workout that included this exercise, keyed by set number.
    private var previousSets: [Int: ExerciseSet] {
        guard let exercise = workoutExercise.exercise else { return [:] }
        let referenceDate = workoutExercise.workout?.date ?? Date()
        guard let previous = exercise.mostRecentWorkoutExercise(before: referenceDate, excluding: workoutExercise) else {
            return [:]
        }
        return Dictionary(previous.orderedSets.map { ($0.setNumber, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private var rows: [SetRow] {
        let previous = previousSets
        return workoutExercise.orderedSets.map { set in
            let earlier = previous[set.setNumber]
            return SetRow(
                id: set.id,
                number: set.setNumber,
                weight: set.weight,
                reps: set.reps,
                time: set.time,
                isCompleted: set.isCompleted,
                previousWeight: earlier?.weight,
                previousReps: earlier?.reps,
                previousTime: earlier?.time
            )
        }
    }

    var body: some View {
        ExerciseSetTable(
            exerciseName: exerciseName,
            isCardio: workoutExercise.exercise?.isCardio ?? false,
            barType: workoutExercise.exercise?.barType,
            rows: rows,
            showNumberPicker: $showNumberPicker,
            numberPickerType: $numberPickerType,
            selectedNumber: $selectedNumber,
            currentExerciseName: $currentExerciseName,
            currentBarType: $currentBarType,
            weightBinding: { row in
                Binding(get: { set(for: row)?.weight }, set: { set(for: row)?.weight = $0 })
            },
            repsBinding: { row in
                Binding(
                    get: { set(for: row)?.reps.map { Double($0) } },
                    set: { set(for: row)?.reps = $0.map { Int($0) } }
                )
            },
            timeBinding: { row in
                Binding(
                    get: { set(for: row)?.time ?? "" },
                    set: { set(for: row)?.time = $0.isEmpty ? nil : $0 }
                )
            },
            onToggleCompleted: { row in set(for: row)?.isCompleted.toggle() },
            onDeleteSet: { row in
                if let set = set(for: row) { deleteSet(set) }
            },
            onAddSet: addSet,
            onRemove: onRemove
        )
    }

    private func set(for row: SetRow) -> ExerciseSet? {
        (workoutExercise.sets ?? []).first { $0.id == row.id }
    }

    private func addSet() {
        let current = workoutExercise.orderedSets
        let previous = current.last
        let newSet = ExerciseSet(setNumber: (current.map { $0.setNumber }.max() ?? 0) + 1,
                                 reps: previous?.reps,
                                 weight: previous?.weight)
        workoutExercise.sets = current + [newSet]
    }

    private func deleteSet(_ set: ExerciseSet) {
        let remaining = workoutExercise.orderedSets.filter { $0.id != set.id }
        for (index, remainingSet) in remaining.enumerated() {
            remainingSet.setNumber = index + 1
        }
        workoutExercise.sets = remaining
        if set.modelContext != nil {
            modelContext.delete(set)
        }
    }
}
