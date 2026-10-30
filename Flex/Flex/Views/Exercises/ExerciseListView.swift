import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var newExercise: Exercise?
    @State private var searchText = ""
    @State private var selectedBodyPart: String?
    @State private var showRecents = false
    @State private var showCustom = false
    @State private var editMode: EditMode = .inactive
    @State private var showDeletedSheet = false

    private var visibleExercises: [Exercise] {
        exercises.filter { !$0.isArchived }
    }

    /// Exercises used in the last 10 workouts, most recent first.
    var recentExercises: [Exercise] {
        var seen = Set<PersistentIdentifier>()
        var result: [Exercise] = []

        for workout in workouts.prefix(10) {
            for workoutExercise in workout.orderedExercises {
                guard let exercise = workoutExercise.exercise, !exercise.isArchived else { continue }
                if seen.insert(exercise.persistentModelID).inserted {
                    result.append(exercise)
                    if result.count >= 50 { return result }
                }
            }
        }
        return result
    }

    /// User-created exercises.
    var customExercises: [Exercise] {
        visibleExercises.filter { !$0.isBuiltIn }
    }

    var filteredExercises: [Exercise] {
        var result: [Exercise]
        if showRecents {
            result = recentExercises
        } else if showCustom {
            result = customExercises
        } else {
            result = visibleExercises
        }

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

    var bodyParts: [String] {
        Array(Set(visibleExercises.map { $0.bodyPart }))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted()
    }

    var searchPlaceholder: String {
        if showRecents {
            return "Search recents"
        } else if showCustom {
            return "Search custom"
        } else if let bodyPart = selectedBodyPart {
            return "Search \(bodyPart.lowercased())"
        } else {
            return "Search exercises"
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                searchField
                filterBar

                List {
                    if filteredExercises.isEmpty {
                        ContentUnavailableView {
                            Label("No Exercises", systemImage: showCustom ? "dumbbell.fill" : "magnifyingglass")
                        } description: {
                            if showCustom {
                                Text("Tap the + button above to create your first custom exercise")
                            } else if !searchText.isEmpty {
                                Text("No exercises match your search")
                            } else {
                                Text("No exercises found")
                            }
                        }
                    } else {
                        ForEach(filteredExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(exercise.bodyPart)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .deleteDisabled(exercise.isBuiltIn)
                            .accessibilityIdentifier("exercise-row-\(exercise.name)")
                        }
                        .onDelete(perform: deleteExercise(indexes:))
                    }
                }
                .environment(\.editMode, $editMode)
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create Exercise", systemImage: "plus", action: addExercise)
                        .accessibilityIdentifier("create-exercise")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            withAnimation {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }) {
                            Label(editMode == .active ? "Done" : "Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(action: { showDeletedSheet = true }) {
                            Label("Show Deleted", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More")
                }
            }
            .sheet(item: $newExercise) { exercise in
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, isNew: true)
                }
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showDeletedSheet) {
                DeletedExercisesView()
            }
        } detail: {
            Text("Select an exercise")
                .navigationTitle("Exercise")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var searchField: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("exercise-search")

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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                filterChip(systemImage: "list.bullet", isSelected: selectedBodyPart == nil && !showRecents && !showCustom, label: "All exercises") {
                    selectedBodyPart = nil
                    showRecents = false
                    showCustom = false
                }

                if !recentExercises.isEmpty {
                    filterChip(systemImage: "clock.arrow.circlepath", isSelected: showRecents, label: "Recent exercises") {
                        selectedBodyPart = nil
                        showRecents = true
                        showCustom = false
                    }
                }

                if !customExercises.isEmpty {
                    filterChip(systemImage: "person.fill", isSelected: showCustom, label: "Custom exercises") {
                        selectedBodyPart = nil
                        showRecents = false
                        showCustom = true
                    }
                }

                ForEach(bodyParts, id: \.self) { bodyPart in
                    Button(action: {
                        selectedBodyPart = bodyPart
                        showRecents = false
                        showCustom = false
                    }) {
                        Text(bodyPart)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedBodyPart == bodyPart ? Color.blue : Color(.systemGray6))
                            .foregroundStyle(selectedBodyPart == bodyPart ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    private func filterChip(systemImage: String, isSelected: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .accessibilityLabel(label)
    }

    private func addExercise() {
        let exercise = Exercise(name: "", bodyPart: Exercise.bodyParts[0])
        context.insert(exercise)
        newExercise = exercise
    }

    private func deleteExercise(indexes: IndexSet) {
        let visible = filteredExercises
        for index in indexes where visible.indices.contains(index) {
            // Soft delete: hide the exercise but keep it so workout history stays intact.
            visible[index].isArchived = true
        }
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(PreviewData.shared.modelContainer)
}
