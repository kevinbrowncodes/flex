import SwiftUI
import SwiftData

struct AddExerciseToTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Exercise> { $0.isArchived == false }, sort: \Exercise.name) private var exercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedBodyPart: String?
    @State private var newExercise: Exercise?

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
                        Button(action: { select(exercise) }) {
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

                                if isSelected(exercise) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .accessibilityIdentifier("pick-exercise-\(exercise.name)")
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Create", systemImage: "plus.circle") {
                        let exercise = Exercise(name: "", bodyPart: Exercise.bodyParts[0])
                        context.insert(exercise)
                        newExercise = exercise
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $newExercise) { exercise in
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, isNew: true) { saved in
                        if !isSelected(saved) {
                            selectedExercises.append(saved)
                        }
                    }
                }
                .interactiveDismissDisabled()
            }
        }
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.persistentModelID == exercise.persistentModelID }
    }

    private func select(_ exercise: Exercise) {
        guard !isSelected(exercise) else { return }
        selectedExercises.append(exercise)
        dismiss()
    }
}

/// Search field shared by the exercise pickers.
struct ExerciseSearchBar: View {
    @Binding var searchText: String
    var placeholder = "Search exercises"

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("exercise-picker-search")

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

/// Horizontal "All / Arms / Back / …" chips shared by the exercise pickers.
struct BodyPartFilterBar: View {
    let bodyParts: [String]
    @Binding var selectedBodyPart: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                chip("All", isSelected: selectedBodyPart == nil) { selectedBodyPart = nil }
                ForEach(bodyParts, id: \.self) { bodyPart in
                    chip(bodyPart, isSelected: selectedBodyPart == bodyPart) { selectedBodyPart = bodyPart }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

#Preview {
    AddExerciseToTemplateView(selectedExercises: .constant([]))
        .modelContainer(PreviewData.shared.modelContainer)
}
