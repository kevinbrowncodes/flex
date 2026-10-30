import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allExercises: [Exercise]
    @Bindable var exercise: Exercise
    let isNew: Bool
    /// Called after a new exercise is saved (used by pickers to auto-select it).
    var onSave: ((Exercise) -> Void)?

    init(exercise: Exercise, isNew: Bool = false, onSave: ((Exercise) -> Void)? = nil) {
        self.exercise = exercise
        self.isNew = isNew
        self.onSave = onSave
    }

    private var trimmedName: String {
        exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Another exercise already uses this name (case-insensitive). Duplicates get merged on launch,
    /// which would silently discard this one, so block the save instead.
    private var hasDuplicateName: Bool {
        guard !trimmedName.isEmpty else { return false }
        return allExercises.contains { other in
            other.persistentModelID != exercise.persistentModelID &&
            other.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !exercise.bodyPart.isEmpty && !hasDuplicateName
    }

    private var history: [WorkoutExercise] {
        (exercise.workoutExercises ?? [])
            .filter { $0.workout != nil }
            .sorted { ($0.workout?.date ?? .distantPast) > ($1.workout?.date ?? .distantPast) }
    }

    var body: some View {
        Form {
            Section {
                if exercise.isBuiltIn {
                    LabeledContent("Name", value: exercise.name)
                    LabeledContent("Body Part", value: exercise.bodyPart)
                    LabeledContent("Category", value: exercise.category)
                } else {
                    TextField("Exercise name", text: $exercise.name)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("exercise-name")

                    Picker("Body Part", selection: $exercise.bodyPart) {
                        ForEach(Exercise.bodyParts, id: \.self) { bodyPart in
                            Text(bodyPart).tag(bodyPart)
                        }
                    }

                    Picker("Category", selection: $exercise.category) {
                        ForEach(Exercise.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }

                if !exercise.isBuiltIn || exercise.usesBarbell {
                    Picker("Bar Type", selection: $exercise.barType) {
                        Text("None").tag(nil as BarType?)
                        ForEach(BarType.allCases, id: \.self) { barType in
                            Text(barType.displayName).tag(barType as BarType?)
                        }
                    }
                }
            } header: {
                Text("Exercise Details")
            } footer: {
                if hasDuplicateName {
                    Text("An exercise named “\(trimmedName)” already exists.")
                        .foregroundStyle(.red)
                } else if exercise.isBuiltIn {
                    Text("Built-in exercises can't be renamed. Create a custom exercise for variations.")
                } else if isNew {
                    Text("Choose a bar type to enable the plate calculator for this exercise.")
                }
            }

            if !isNew {
                Section("History") {
                    LabeledContent("Times Performed", value: "\(history.count)")
                    if let best = history.compactMap({ $0.bestWeight }).max() {
                        LabeledContent("Best Weight", value: Formatting.weightWithUnit(best))
                    }
                    if let last = history.first?.workout?.date {
                        LabeledContent("Last Performed") {
                            Text(last, format: .dateTime.month().day().year())
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Exercise" : "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exercise.name = trimmedName
                        onSave?(exercise)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("save-exercise")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(exercise)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: PreviewData.shared.exercise)
    }
    .modelContainer(PreviewData.shared.modelContainer)
}

#Preview("New Exercise") {
    NavigationStack {
        ExerciseDetailView(exercise: Exercise(name: "", bodyPart: "Chest"), isNew: true)
    }
    .modelContainer(PreviewData.shared.modelContainer)
}
