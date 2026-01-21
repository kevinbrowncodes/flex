import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var newExercise: Exercise?
    @State private var searchText = ""
    @State private var selectedBodyPart: String?
    
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
        
        return result
    }
    
    var bodyParts: [String] {
        let allBodyParts = exercises.map { $0.bodyPart }
        return Array(Set(allBodyParts)).sorted()
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedBodyPart = nil
                        }) {
                            Text("All")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedBodyPart == nil ? Color.blue : Color(.systemGray6))
                                .foregroundStyle(selectedBodyPart == nil ? .white : .primary)
                                .cornerRadius(8)
                        }
                        
                        ForEach(bodyParts, id: \.self) { bodyPart in
                            Button(action: {
                                selectedBodyPart = bodyPart
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
                
                // Exercise list
                List {
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
                    }
                    .onDelete(perform: deleteExercise(indexes:))
                }
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem {
                    Button("Add exercise", systemImage: "plus", action: addExercise)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $newExercise) { exercise in
                NavigationStack {
                    ExerciseDetailView(exercise: exercise, isNew: true)
                }
                .interactiveDismissDisabled()
            }
        } detail: {
            Text("Select an exercise")
                .navigationTitle("Exercise")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func addExercise() {
        let newExercise = Exercise(name: "", bodyPart: "")
        context.insert(newExercise)
        self.newExercise = newExercise
    }
    
    private func deleteExercise(indexes: IndexSet) {
        for index in indexes {
            context.delete(filteredExercises[index])
        }
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(SampleData.shared.modelContainer)
}
