import SwiftUI
import SwiftData

struct WorkoutHistoryCard: View {
    let workout: Workout
    /// Every saved workout, used to work out which lifts were personal records.
    let allWorkouts: [Workout]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    @State private var showEditWorkout = false

    private var prCount: Int {
        workout.calculatePRCount(comparedTo: allWorkouts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(workout.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        showEditWorkout = true
                    } label: {
                        Label("Edit Workout", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.blue)
                        .imageScale(.large)
                        .padding(.vertical, 4)
                }
                .accessibilityLabel("\(workout.title) options")
                .accessibilityIdentifier("workout-options-\(workout.title)")
            }

            HStack(spacing: 20) {
                Label(Formatting.duration(workout.duration), systemImage: "clock")
                Label(Formatting.weightWithUnit(workout.totalVolume), systemImage: "figure.strengthtraining.traditional")
                Label("\(prCount) PR\(prCount == 1 ? "" : "s")", systemImage: "trophy")
                    .foregroundStyle(prCount > 0 ? Color.orange : Color.secondary)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    ForEach(workout.orderedExercises) { workoutExercise in
                        Text("\((workoutExercise.sets ?? []).count) × \(workoutExercise.exercise?.name ?? "Unknown Exercise")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Best Set")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    ForEach(workout.orderedExercises) { workoutExercise in
                        let best = workoutExercise.bestSet ?? workoutExercise.orderedSets.first
                        Text(Formatting.setSummary(weight: best?.weight, reps: best?.reps, time: best?.time) ?? "—")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workout-card-\(workout.title)")
        .confirmationDialog("Delete Workout?", isPresented: $showDeleteAlert, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(workout)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showEditWorkout) {
            EditWorkoutView(workout: workout)
        }
    }
}

#Preview {
    let context = PreviewData.shared.context
    let workouts = (try? context.fetch(FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
    return ScrollView {
        if let first = workouts.first {
            WorkoutHistoryCard(workout: first, allWorkouts: workouts)
                .padding()
        }
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(PreviewData.shared.modelContainer)
}
