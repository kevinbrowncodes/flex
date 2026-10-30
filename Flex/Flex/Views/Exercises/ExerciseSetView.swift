import SwiftUI
import SwiftData

/// One exercise inside an active or edited workout: the set table plus add/remove controls.
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

    private var isCardio: Bool {
        workoutExercise.exercise?.isCardio ?? false
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exerciseName)
                    .font(.headline)
                    .foregroundStyle(.blue)

                Spacer()

                Menu {
                    Button(role: .destructive, action: onRemove) {
                        Label("Remove Exercise", systemImage: "xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.blue)
                        .padding(.vertical, 4)
                }
                .accessibilityLabel("\(exerciseName) options")
            }

            headerRow

            VStack(spacing: 8) {
                ForEach(workoutExercise.orderedSets) { set in
                    setRow(set)
                }
            }

            Button(action: addSet) {
                Text("+ Add Set")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .accessibilityIdentifier("add-set-\(exerciseName)")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var headerRow: some View {
        HStack {
            Text("Set")
                .frame(width: 35, alignment: .leading)

            Text("Previous")
                .frame(width: 95, alignment: .leading)

            if isCardio {
                Text("Time")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("lbs")
                    .frame(width: 65, alignment: .center)
                    .padding(8)

                Text("Reps")
                    .frame(width: 65, alignment: .center)
                    .padding(8)
            }

            Image(systemName: "checkmark")
                .frame(width: 35)
                .opacity(0)
        }
        .font(.subheadline)
        .fontWeight(.semibold)
    }

    @ViewBuilder
    private func setRow(_ set: ExerciseSet) -> some View {
        let previous = previousSets[set.setNumber]

        HStack {
            Text("\(set.setNumber)")
                .frame(width: 35, alignment: .leading)
                .font(.body)
                .fontWeight(.medium)

            Text(Formatting.compactSetSummary(weight: previous?.weight, reps: previous?.reps, time: previous?.time) ?? "—")
                .frame(width: 95, alignment: .leading)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .font(.system(.body, design: .monospaced))

            if isCardio {
                TextField("0:00", text: Binding(
                    get: { set.time ?? "" },
                    set: { set.time = $0.isEmpty ? nil : $0 }
                ))
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("time-\(exerciseName)-\(set.setNumber)")
            } else {
                Button(action: {
                    selectedNumber = Binding(get: { set.weight }, set: { set.weight = $0 })
                    currentExerciseName = exerciseName
                    currentBarType = workoutExercise.exercise?.barType
                    numberPickerType = .weight
                    withAnimation { showNumberPicker = true }
                }) {
                    Text(set.weight.map { Formatting.weight($0) } ?? "")
                        .frame(width: 65)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Weight")
                .accessibilityValue(set.weight.map { Formatting.weight($0) } ?? "empty")
                .accessibilityIdentifier("weight-\(exerciseName)-\(set.setNumber)")

                Button(action: {
                    selectedNumber = Binding(
                        get: { set.reps.map { Double($0) } },
                        set: { set.reps = $0.map { Int($0) } }
                    )
                    currentExerciseName = exerciseName
                    currentBarType = nil
                    numberPickerType = .reps
                    withAnimation { showNumberPicker = true }
                }) {
                    Text(set.reps.map { String($0) } ?? "")
                        .frame(width: 65)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reps")
                .accessibilityValue(set.reps.map { String($0) } ?? "empty")
                .accessibilityIdentifier("reps-\(exerciseName)-\(set.setNumber)")
            }

            Button(action: { set.isCompleted.toggle() }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .gray.opacity(0.4))
            }
            .frame(width: 35)
            .accessibilityLabel(set.isCompleted ? "Completed" : "Mark complete")
            .accessibilityIdentifier("complete-\(exerciseName)-\(set.setNumber)")
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteSet(set)
            } label: {
                Label("Delete Set", systemImage: "trash")
            }
        }
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
