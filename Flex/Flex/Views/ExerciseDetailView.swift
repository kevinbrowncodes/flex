import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var exercise: Exercise
    let isNew: Bool
    
    let bodyParts = ["Arms", "Back", "Cardio", "Chest", "Core", "Full Body", "Legs", "Shoulders"]
    
    init(exercise: Exercise, isNew: Bool = false) {
        self.exercise = exercise
        self.isNew = isNew
    }
    
    var body: some View {
        Form {
            TextField("Exercise name", text: $exercise.name)
                .autocorrectionDisabled()
            
            Picker("Body Part", selection: $exercise.bodyPart) {
                ForEach(bodyParts, id: \.self) { bodyPart in
                    Text(bodyPart).tag(bodyPart)
                }
            }
        }
        .navigationTitle(isNew ? "New Exercise" : "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                    .disabled(exercise.name.isEmpty || exercise.bodyPart.isEmpty)
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
        ExerciseDetailView(exercise: SampleData.shared.exercise)
    }
}

#Preview("New Exercise") {
    NavigationStack {
        ExerciseDetailView(exercise: SampleData.shared.exercise, isNew: true)
    }
}
