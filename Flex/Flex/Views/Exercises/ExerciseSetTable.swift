import SwiftUI

/// One row of the set table, as plain values, so the same table serves a workout in progress
/// (`LiveExerciseSetView`) and a saved one being edited (`ExerciseSetView`).
struct SetRow: Identifiable, Equatable {
    let id: UUID
    let number: Int
    var weight: Double?
    var reps: Int?
    var time: String?
    var isCompleted: Bool
    /// The matching set from the most recent earlier workout of this exercise ("Previous").
    var previousWeight: Double?
    var previousReps: Int?
    var previousTime: String?
}

/// The set table under an exercise's name: header, one row per set, "+ Add Set" and the
/// Remove Exercise menu. Every change goes out through a closure; the table holds no model.
struct ExerciseSetTable: View {
    let exerciseName: String
    let isCardio: Bool
    let barType: BarType?
    let rows: [SetRow]
    @Binding var showNumberPicker: Bool
    @Binding var numberPickerType: NumberPickerType
    @Binding var selectedNumber: Binding<Double?>?
    @Binding var currentExerciseName: String?
    @Binding var currentBarType: BarType?
    var weightBinding: (SetRow) -> Binding<Double?>
    var repsBinding: (SetRow) -> Binding<Double?>
    var timeBinding: (SetRow) -> Binding<String>
    var onToggleCompleted: (SetRow) -> Void
    var onDeleteSet: (SetRow) -> Void
    var onAddSet: () -> Void
    var onRemove: () -> Void

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
                ForEach(rows) { row in
                    setRow(row)
                }
            }

            Button(action: onAddSet) {
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
    private func setRow(_ row: SetRow) -> some View {
        HStack {
            Text("\(row.number)")
                .frame(width: 35, alignment: .leading)
                .font(.body)
                .fontWeight(.medium)

            Text(Formatting.compactSetSummary(weight: row.previousWeight, reps: row.previousReps, time: row.previousTime) ?? "—")
                .frame(width: 95, alignment: .leading)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .font(.system(.body, design: .monospaced))

            if isCardio {
                TextField("0:00", text: timeBinding(row))
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("time-\(exerciseName)-\(row.number)")
            } else {
                Button(action: {
                    selectedNumber = weightBinding(row)
                    currentExerciseName = exerciseName
                    currentBarType = barType
                    numberPickerType = .weight
                    withAnimation { showNumberPicker = true }
                }) {
                    Text(row.weight.map { Formatting.weight($0) } ?? "")
                        .frame(width: 65)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Weight")
                .accessibilityValue(row.weight.map { Formatting.weight($0) } ?? "empty")
                .accessibilityIdentifier("weight-\(exerciseName)-\(row.number)")

                Button(action: {
                    selectedNumber = repsBinding(row)
                    currentExerciseName = exerciseName
                    currentBarType = nil
                    numberPickerType = .reps
                    withAnimation { showNumberPicker = true }
                }) {
                    Text(row.reps.map { String($0) } ?? "")
                        .frame(width: 65)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reps")
                .accessibilityValue(row.reps.map { String($0) } ?? "empty")
                .accessibilityIdentifier("reps-\(exerciseName)-\(row.number)")
            }

            Button(action: { onToggleCompleted(row) }) {
                Image(systemName: row.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(row.isCompleted ? .green : .gray.opacity(0.4))
            }
            .frame(width: 35)
            .accessibilityLabel(row.isCompleted ? "Completed" : "Mark complete")
            .accessibilityIdentifier("complete-\(exerciseName)-\(row.number)")
        }
        .contextMenu {
            Button(role: .destructive) {
                onDeleteSet(row)
            } label: {
                Label("Delete Set", systemImage: "trash")
            }
        }
    }
}
