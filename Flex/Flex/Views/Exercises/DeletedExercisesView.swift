import SwiftUI
import SwiftData

struct DeletedExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Exercise> { exercise in
        exercise.isArchived == true
    }, sort: \Exercise.name) private var deletedExercises: [Exercise]

    private var groupedExercises: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: deletedExercises) { exercise in
            String(exercise.name.prefix(1).uppercased())
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.0) { section, exercises in
                    Section(header: Text(section)) {
                        ForEach(exercises) { exercise in
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

                                Button(action: { exercise.isArchived = false }) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Restore \(exercise.name)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Deleted Exercises")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .overlay {
                if deletedExercises.isEmpty {
                    ContentUnavailableView(
                        "No Deleted Exercises",
                        systemImage: "checkmark.circle",
                        description: Text("Deleted exercises will appear here")
                    )
                }
            }
        }
    }
}

#Preview("Deleted Exercises") {
    DeletedExercisesView()
        .modelContainer(PreviewData.shared.modelContainer)
}
