import SwiftUI
import SwiftData

struct AddExerciseToWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Exercise> { $0.isArchived == false }, sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var searchText = ""
    @State private var selectedBodyPart: String?
    @State private var selectedCategory: String?
    @State private var selectedExercises = Set<PersistentIdentifier>()
    @State private var sortOption: SortOption = .name
    @State private var newExercise: Exercise?
    @State private var infoExercise: Exercise?
    var onAddExercises: ([Exercise]) -> Void

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case frequency = "Frequency"
        case lastPerformed = "Last Performed"
    }

    var filteredExercises: [Exercise] {
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

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        switch sortOption {
        case .name:
            result = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .frequency:
            let frequency = exerciseFrequencies
            result = result.sorted { (frequency[$0.persistentModelID] ?? 0) > (frequency[$1.persistentModelID] ?? 0) }
        case .lastPerformed:
            let lastPerformed = lastPerformedDates
            result = result.sorted {
                let lhs = lastPerformed[$0.persistentModelID]
                let rhs = lastPerformed[$1.persistentModelID]
                switch (lhs, rhs) {
                case let (l?, r?): return l > r
                case (_?, nil): return true
                default: return false
                }
            }
        }

        return result
    }

    /// Number of workouts that included each exercise.
    private var exerciseFrequencies: [PersistentIdentifier: Int] {
        var counts: [PersistentIdentifier: Int] = [:]
        for workout in workouts {
            for id in Set((workout.exercises ?? []).compactMap { $0.exercise?.persistentModelID }) {
                counts[id, default: 0] += 1
            }
        }
        return counts
    }

    /// Most recent workout date for each exercise (workouts are sorted newest first).
    private var lastPerformedDates: [PersistentIdentifier: Date] {
        var dates: [PersistentIdentifier: Date] = [:]
        for workout in workouts {
            for workoutExercise in workout.exercises ?? [] {
                guard let id = workoutExercise.exercise?.persistentModelID, dates[id] == nil else { continue }
                dates[id] = workout.date
            }
        }
        return dates
    }

    var availableBodyParts: [String] {
        Set(exercises.map { $0.bodyPart }).sorted()
    }

    var availableCategories: [String] {
        Set(exercises.map { $0.category }).sorted()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Search", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("exercise-picker-search")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                filterRow

                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: { toggle(exercise) }) {
                            exerciseRow(for: exercise)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(rowBackground(for: exercise))
                        .accessibilityIdentifier("pick-exercise-\(exercise.name)")
                    }
                }
                .listStyle(.plain)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create", systemImage: "plus.circle") {
                        let exercise = Exercise(name: "", bodyPart: Exercise.bodyParts[0])
                        context.insert(exercise)
                        newExercise = exercise
                    }
                    .accessibilityIdentifier("create-exercise")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addSelected) {
                        Text(selectedExercises.isEmpty ? "Add" : "Add (\(selectedExercises.count))")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedExercises.isEmpty)
                    .accessibilityIdentifier("add-selected-exercises")
                }
            }
            .sheet(item: $newExercise) { exercise in
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, isNew: true) { saved in
                        selectedExercises.insert(saved.persistentModelID)
                    }
                }
                .interactiveDismissDisabled()
            }
            .sheet(item: $infoExercise) { exercise in
                NavigationStack {
                    ExerciseDetailView(exercise: exercise)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { infoExercise = nil }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Helper Views

    private var filterRow: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Any Body Part") { selectedBodyPart = nil }
                Divider()
                ForEach(availableBodyParts, id: \.self) { bodyPart in
                    Button(bodyPart) { selectedBodyPart = bodyPart }
                }
            } label: {
                filterLabel(selectedBodyPart ?? "Any Body Part")
            }

            Menu {
                Button("Any Category") { selectedCategory = nil }
                Divider()
                ForEach(availableCategories, id: \.self) { category in
                    Button(category) { selectedCategory = category }
                }
            } label: {
                filterLabel(selectedCategory ?? "Any Category")
            }

            Menu {
                Picker("Sort by", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .accessibilityLabel("Sort")

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func filterLabel(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }

    private func exerciseRow(for exercise: Exercise) -> some View {
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

            if selectedExercises.contains(exercise.persistentModelID) {
                Image(systemName: "checkmark")
                    .font(.title3)
                    .foregroundStyle(Color.blue)
            } else {
                Button(action: { infoExercise = exercise }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(Color.blue)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("\(exercise.name) details")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func rowBackground(for exercise: Exercise) -> Color {
        selectedExercises.contains(exercise.persistentModelID) ? Color.blue.opacity(0.1) : Color.clear
    }

    private func toggle(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.persistentModelID) {
            selectedExercises.remove(exercise.persistentModelID)
        } else {
            selectedExercises.insert(exercise.persistentModelID)
        }
    }

    private func addSelected() {
        let exercisesToAdd = exercises.filter { selectedExercises.contains($0.persistentModelID) }
        onAddExercises(exercisesToAdd)
        dismiss()
    }
}

#Preview {
    AddExerciseToWorkoutView(onAddExercises: { _ in })
        .modelContainer(PreviewData.shared.modelContainer)
}
