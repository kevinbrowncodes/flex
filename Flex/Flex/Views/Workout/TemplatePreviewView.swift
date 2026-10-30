import SwiftUI
import SwiftData

struct TemplatePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [Workout]
    let template: WorkoutTemplate
    let onStartWorkout: () -> Void
    let onEdit: () -> Void
    @State private var infoExercise: Exercise?

    private var lastPerformed: Date? {
        workouts
            .filter { $0.title == template.name }
            .map { $0.date }
            .max()
    }

    private var orderedExercises: [TemplateExercise] {
        template.templateExercisesArray.sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let lastPerformed {
                    HStack {
                        Text("Last Performed: \(lastPerformed, format: .dateTime.month().day().year())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, templateExercise in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(templateExercise.setsArray.count) × \(templateExercise.exercise?.name ?? "Unknown")")
                                        .font(.body)
                                        .fontWeight(.medium)

                                    Text(templateExercise.exercise?.bodyPart ?? "Unknown")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let exercise = templateExercise.exercise {
                                    Button(action: { infoExercise = exercise }) {
                                        Image(systemName: "info.circle")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                    .accessibilityLabel("\(exercise.name) details")
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))

                            if index < orderedExercises.count - 1 {
                                Divider()
                                    .padding(.leading, 84)
                            }
                        }

                        if orderedExercises.isEmpty {
                            Text("This template has no exercises yet.")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 40)
                        }
                    }
                }
                .background(Color(.systemBackground))

                Button(action: onStartWorkout) {
                    Text("Start Workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("start-template-workout")
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", action: onEdit)
                        .foregroundStyle(.blue)
                }
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
}

#Preview {
    let context = PreviewData.shared.context
    let template = (try? context.fetch(FetchDescriptor<WorkoutTemplate>()))?.first ?? WorkoutTemplate(name: "HEAVY DUTY PUSH", exercises: [])
    return TemplatePreviewView(template: template, onStartWorkout: {}, onEdit: {})
        .modelContainer(PreviewData.shared.modelContainer)
}
