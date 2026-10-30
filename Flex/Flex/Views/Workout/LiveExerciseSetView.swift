import SwiftUI

/// One exercise inside the workout in progress: the set table over a `LiveExercise`, every change
/// sent to the session as a `LiveWorkoutEdit` (STORY_002).
struct LiveExerciseSetView: View {
    @Environment(LiveWorkoutSession.self) private var session
    let exercise: LiveExercise
    @Binding var showNumberPicker: Bool
    @Binding var numberPickerType: NumberPickerType
    @Binding var selectedNumber: Binding<Double?>?
    @Binding var currentExerciseName: String?
    @Binding var currentBarType: BarType?
    var onRemove: () -> Void

    private var rows: [SetRow] {
        exercise.sets.enumerated().map { index, set in
            let previous = exercise.previousSet(at: index)
            return SetRow(
                id: set.id,
                number: index + 1,
                weight: set.weight,
                reps: set.reps,
                time: set.time,
                isCompleted: set.isCompleted,
                previousWeight: previous?.weight,
                previousReps: previous?.reps,
                previousTime: previous?.time
            )
        }
    }

    var body: some View {
        ExerciseSetTable(
            exerciseName: exercise.name,
            isCardio: exercise.isCardio,
            barType: exercise.barType,
            rows: rows,
            showNumberPicker: $showNumberPicker,
            numberPickerType: $numberPickerType,
            selectedNumber: $selectedNumber,
            currentExerciseName: $currentExerciseName,
            currentBarType: $currentBarType,
            weightBinding: { row in
                Binding(
                    get: { session.workout?.set(withID: row.id)?.weight },
                    set: { session.apply(.setWeight(setID: row.id, weight: $0)) }
                )
            },
            repsBinding: { row in
                Binding(
                    get: { session.workout?.set(withID: row.id)?.reps.map { Double($0) } },
                    set: { session.apply(.setReps(setID: row.id, reps: $0.map { Int($0) })) }
                )
            },
            timeBinding: { row in
                Binding(
                    get: { session.workout?.set(withID: row.id)?.time ?? "" },
                    set: { session.apply(.setTime(setID: row.id, time: $0.isEmpty ? nil : $0)) }
                )
            },
            onToggleCompleted: { row in
                let isCompleted = session.workout?.set(withID: row.id)?.isCompleted ?? false
                session.apply(.setCompleted(setID: row.id, isCompleted: !isCompleted))
            },
            onDeleteSet: { row in
                session.apply(.deleteSet(exerciseID: exercise.id, setID: row.id))
            },
            onAddSet: {
                // The new set copies the previous set's weight and reps, as the saved-workout editor does.
                let previous = exercise.sets.last
                session.apply(.addSet(exerciseID: exercise.id, set: LiveSet(reps: previous?.reps, weight: previous?.weight)))
            },
            onRemove: onRemove
        )
    }
}
