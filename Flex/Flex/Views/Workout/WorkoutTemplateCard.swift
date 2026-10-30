import SwiftUI

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    private var exercisePreview: String {
        let exercises = template.templateExercisesArray
            .sorted { $0.order < $1.order }
            .compactMap { $0.exercise }
        let names = exercises.prefix(3).map { $0.name }
        let preview = names.joined(separator: ", ")
        return names.count < exercises.count ? "\(preview)..." : preview
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Template", systemImage: "square.and.pencil")
                        }

                        Button(action: onRename) {
                            Label("Rename", systemImage: "character.cursor.ibeam")
                        }

                        Divider()

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.blue)
                            .padding(.vertical, 4)
                    }
                    .accessibilityLabel("\(template.name) options")
                }

                Text(exercisePreview.isEmpty ? "No exercises" : exercisePreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(template.createdDate, format: .dateTime.month().day().year())
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("template-card-\(template.name)")
    }
}

#Preview {
    WorkoutTemplateCard(
        template: WorkoutTemplate(name: "Push Day", exercises: []),
        onTap: {}, onEdit: {}, onRename: {}, onDelete: {}
    )
    .padding()
}
