import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var templateName = "New Template"
    @State private var editingName = false
    @State private var editedName = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showingExercisePicker = false
    let folder: TemplateFolder?

    init(folder: TemplateFolder? = nil) {
        self.folder = folder
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text(templateName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .onTapGesture {
                            editedName = templateName
                            editingName = true
                        }

                    Spacer()

                    Menu {
                        Button("Rename", systemImage: "pencil") {
                            editedName = templateName
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
                        .padding(.top)

                        if selectedExercises.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No exercises added")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Tap 'Add Exercises' to get started")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(selectedExercises) { exercise in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Text(exercise.bodyPart)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Button(action: {
                                            selectedExercises.removeAll { $0.persistentModelID == exercise.persistentModelID }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .accessibilityLabel("Remove \(exercise.name)")
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveTemplate)
                        .fontWeight(.semibold)
                        .disabled(selectedExercises.isEmpty)
                        .accessibilityIdentifier("save-template")
                }
            }
            .alert("Template Name", isPresented: $editingName) {
                TextField("Template name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        templateName = name
                    }
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                AddExerciseToTemplateView(selectedExercises: $selectedExercises)
            }
        }
    }

    private func saveTemplate() {
        let templateExercises = selectedExercises.enumerated().map { index, exercise in
            TemplateExercise(exercise: exercise, sets: [TemplateSet(setNumber: 1)], order: index)
        }
        let template = WorkoutTemplate(name: templateName, templateExercises: templateExercises)
        template.templateFolder = folder
        modelContext.insert(template)
        dismiss()
    }
}

#Preview {
    CreateTemplateView()
        .modelContainer(PreviewData.shared.modelContainer)
}
