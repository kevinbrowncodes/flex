import SwiftUI
import SwiftData

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var template: WorkoutTemplate
    @State private var editingName = false
    @State private var editedName = ""
    @State private var showingExercisePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text(template.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Spacer()

                    Menu {
                        Button("Rename", systemImage: "pencil") {
                            editedName = template.name
                            editingName = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.blue)
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Template options")
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(template.templateExercisesArray.sorted(by: { $0.order < $1.order })) { templateExercise in
                            TemplateExerciseRow(templateExercise: templateExercise, template: template)
                        }

                        Button(action: { showingExercisePicker = true }) {
                            Text("Add Exercises")
                                .font(.headline)
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .accessibilityIdentifier("add-exercises")
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("edit-template-done")
                }
            }
            .alert("Rename Template", isPresented: $editingName) {
                TextField("Template name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        template.name = name
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                AddExerciseToTemplateEditView(template: template)
            }
        }
    }
}

struct TemplateExerciseRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var templateExercise: TemplateExercise
    @Bindable var template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(templateExercise.exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                    .foregroundStyle(.blue)

                Spacer()

                Menu {
                    Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                        template.templateExercises = template.templateExercisesArray.filter { $0.id != templateExercise.id }
                        modelContext.delete(templateExercise)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.blue)
                        .padding(.vertical, 4)
                }
                .accessibilityLabel("\(templateExercise.exercise?.name ?? "Exercise") options")
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                Text("Set")
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("lbs")
                    .frame(width: 80, alignment: .center)
                Text("Reps")
                    .frame(width: 80, alignment: .center)
                Color.clear.frame(width: 30)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal)

            ForEach(templateExercise.setsArray.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                TemplateSetRow(set: set) {
                    deleteSet(set)
                }
            }

            Button(action: addSet) {
                Text("+ Add Set")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func addSet() {
        let current = templateExercise.setsArray.sorted { $0.setNumber < $1.setNumber }
        let last = current.last
        let newSet = TemplateSet(setNumber: (current.map { $0.setNumber }.max() ?? 0) + 1, reps: last?.reps, weight: last?.weight)
        templateExercise.setsArray = current + [newSet]
    }

    private func deleteSet(_ set: TemplateSet) {
        let remaining = templateExercise.setsArray.filter { $0.id != set.id }.sorted { $0.setNumber < $1.setNumber }
        for (index, remainingSet) in remaining.enumerated() {
            remainingSet.setNumber = index + 1
        }
        templateExercise.setsArray = remaining
        modelContext.delete(set)
    }
}

struct TemplateSetRow: View {
    @Bindable var set: TemplateSet
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(.body)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Spacer()

            TextField("lbs", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.body)
                .frame(width: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .accessibilityLabel("Weight")

            TextField("reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body)
                .frame(width: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .accessibilityLabel("Reps")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle")
                    .font(.body)
                    .foregroundStyle(.red)
            }
            .frame(width: 30)
            .accessibilityLabel("Delete set \(set.setNumber)")
        }
        .padding(.horizontal)
    }
}

struct AddExerciseToTemplateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Exercise> { $0.isArchived == false }, sort: \Exercise.name) private var exercises: [Exercise]
    @Bindable var template: WorkoutTemplate
    @State private var searchText = ""
    @State private var selectedBodyPart: String?

    private var filteredExercises: [Exercise] {
        var result = exercises

        if !searchText.isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.bodyPart.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let bodyPart = selectedBodyPart {
            result = result.filter { $0.bodyPart == bodyPart }
        }

        return result
    }

    private var bodyParts: [String] {
        Set(exercises.map { $0.bodyPart }).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ExerciseSearchBar(searchText: $searchText)
                BodyPartFilterBar(bodyParts: bodyParts, selectedBodyPart: $selectedBodyPart)

                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: { add(exercise) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(exercise.bodyPart)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .accessibilityIdentifier("pick-exercise-\(exercise.name)")
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func add(_ exercise: Exercise) {
        let current = template.templateExercisesArray
        let nextOrder = (current.map { $0.order }.max() ?? -1) + 1
        let templateExercise = TemplateExercise(exercise: exercise, sets: [TemplateSet(setNumber: 1)], order: nextOrder)
        modelContext.insert(templateExercise)
        template.templateExercises = current + [templateExercise]
        dismiss()
    }
}

#Preview {
    let context = PreviewData.shared.context
    let template = (try? context.fetch(FetchDescriptor<WorkoutTemplate>()))?.first ?? WorkoutTemplate(name: "Push Day", exercises: [])
    return EditTemplateView(template: template)
        .modelContainer(PreviewData.shared.modelContainer)
}
