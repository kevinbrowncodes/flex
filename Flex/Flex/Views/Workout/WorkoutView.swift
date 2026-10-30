import SwiftUI
import SwiftData

enum TemplateSortOrder: String, CaseIterable {
    case name
    case dateCreated

    var title: String {
        switch self {
        case .name: return "Sort by Name"
        case .dateCreated: return "Sort by Date"
        }
    }

    func sort(_ templates: [WorkoutTemplate]) -> [WorkoutTemplate] {
        switch self {
        case .name:
            return templates.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateCreated:
            return templates.sorted { $0.createdDate > $1.createdDate }
        }
    }
}

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LiveWorkoutSession.self) private var session
    @Environment(PreferencesManager.self) private var preferences
    @Query private var templates: [WorkoutTemplate]
    @Query(sort: \TemplateFolder.name) private var folders: [TemplateFolder]
    @AppStorage("templateSortOrder") private var sortOrderRawValue = TemplateSortOrder.name.rawValue

    @State private var showingWorkout = false
    @State private var showingNewTemplate = false
    @State private var showingNewFolder = false
    @State private var previewingTemplate: WorkoutTemplate?
    @State private var editingTemplate: WorkoutTemplate?
    @State private var folderForNewTemplate: TemplateFolder?
    @State private var expandedFolders: Set<UUID> = []

    @State private var renamingTemplate: WorkoutTemplate?
    @State private var renamingFolder: TemplateFolder?
    @State private var isRenamingTemplate = false
    @State private var isRenamingFolder = false
    @State private var renameText = ""

    @State private var templateToDelete: WorkoutTemplate?
    @State private var folderToDelete: TemplateFolder?
    @State private var isConfirmingTemplateDelete = false
    @State private var isConfirmingFolderDelete = false

    private var sortOrder: TemplateSortOrder {
        TemplateSortOrder(rawValue: sortOrderRawValue) ?? .name
    }

    /// Templates that don't live in a folder.
    private var unorganizedTemplates: [WorkoutTemplate] {
        sortOrder.sort(templates.filter { $0.templateFolder == nil })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Button(action: { startWorkout(from: nil) }) {
                        Text("Start Workout")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .accessibilityIdentifier("start-empty-workout")

                    VStack(alignment: .leading, spacing: 16) {
                        templatesHeader

                        ForEach(folders) { folder in
                            folderSection(folder)
                        }

                        if !unorganizedTemplates.isEmpty {
                            templateGrid(unorganizedTemplates)
                        }

                        if templates.isEmpty && folders.isEmpty {
                            emptyState
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingWorkout) {
                ActiveWorkoutView()
            }
            // A workout saved mid-session (Flex was closed) comes straight back on top (STORY_002).
            .onAppear {
                if session.isActive { showingWorkout = true }
            }
            .sheet(isPresented: $showingNewTemplate) {
                CreateTemplateView()
            }
            .sheet(item: $editingTemplate) { template in
                EditTemplateView(template: template)
            }
            .sheet(item: $previewingTemplate) { template in
                TemplatePreviewView(
                    template: template,
                    onStartWorkout: {
                        previewingTemplate = nil
                        // Let the preview sheet finish dismissing before presenting the workout.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            startWorkout(from: template)
                        }
                    },
                    onEdit: {
                        previewingTemplate = nil
                        editingTemplate = template
                    }
                )
            }
            .sheet(item: $folderForNewTemplate) { folder in
                CreateTemplateView(folder: folder)
            }
            .overlay {
                if showingNewFolder {
                    CreateFolderPopup(isPresented: $showingNewFolder)
                        .animation(.easeInOut(duration: 0.2), value: showingNewFolder)
                }
            }
            .alert("Rename Template", isPresented: $isRenamingTemplate) {
                TextField("Template name", text: $renameText)
                Button("Cancel", role: .cancel) { renamingTemplate = nil }
                Button("Save") {
                    let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        renamingTemplate?.name = name
                    }
                    renamingTemplate = nil
                }
            }
            .alert("Rename Folder", isPresented: $isRenamingFolder) {
                TextField("Folder name", text: $renameText)
                Button("Cancel", role: .cancel) { renamingFolder = nil }
                Button("Save") {
                    let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        renamingFolder?.name = name
                    }
                    renamingFolder = nil
                }
            }
            // Alerts, not confirmation dialogs: iOS 26 anchors a dialog to its source on iPhone and drops
            // the cancel button, so Cancel vanished (BUG_001).
            .alert(
                "Delete Template?",
                isPresented: $isConfirmingTemplateDelete,
                presenting: templateToDelete
            ) { template in
                Button("Delete \"\(template.name)\"", role: .destructive) {
                    modelContext.delete(template)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This cannot be undone.")
            }
            .alert(
                "Delete Folder?",
                isPresented: $isConfirmingFolderDelete,
                presenting: folderToDelete
            ) { folder in
                Button("Delete \"\(folder.name)\"", role: .destructive) {
                    modelContext.delete(folder)
                }
                Button("Cancel", role: .cancel) {}
            } message: { folder in
                let count = folder.templateCount
                Text(count == 0
                     ? "This cannot be undone."
                     : "The \(count) template\(count == 1 ? "" : "s") inside will be deleted too. This cannot be undone.")
            }
        }
    }

    // MARK: - Starting

    /// Starts a live workout (empty, or from a template) and shows it (STORY_002).
    private func startWorkout(from template: WorkoutTemplate?) {
        var start = Date()
        #if DEBUG
        start = start.addingTimeInterval(DemoMode.current?.workoutStartOffset ?? 0)
        #endif
        session.start(LiveWorkoutBridge.start(from: template, at: start, restSeconds: preferences.restSeconds))
        showingWorkout = true
    }

    // MARK: - Sections

    private var templatesHeader: some View {
        HStack {
            Text("Templates")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: { showingNewTemplate = true }) {
                Image(systemName: "plus")
                    .font(.title3)
            }
            .accessibilityLabel("New Template")
            .accessibilityIdentifier("new-template")

            Button(action: { showingNewFolder = true }) {
                Image(systemName: "folder")
                    .font(.title3)
            }
            .accessibilityLabel("New Folder")
            .accessibilityIdentifier("new-folder")

            Menu {
                Picker("Sort", selection: $sortOrderRawValue) {
                    ForEach(TemplateSortOrder.allCases, id: \.rawValue) { order in
                        Text(order.title).tag(order.rawValue)
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
            }
            .accessibilityLabel("Sort Templates")
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func folderSection(_ folder: TemplateFolder) -> some View {
        let isExpanded = expandedFolders.contains(folder.id)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: { toggle(folder) }) {
                    HStack {
                        Image(systemName: isExpanded ? "folder.fill" : "folder")
                            .foregroundStyle(.blue)
                        Text("\(folder.name) (\(folder.templateCount))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("folder-\(folder.name)")

                Menu {
                    Button(action: { toggle(folder) }) {
                        Label(isExpanded ? "Collapse Folder" : "Expand Folder",
                              systemImage: isExpanded ? "arrow.up.backward.and.arrow.down.forward" : "arrow.down.forward.and.arrow.up.backward")
                    }
                    Button(action: { folderForNewTemplate = folder }) {
                        Label("Add Template", systemImage: "plus")
                    }
                    Button(action: {
                        renameText = folder.name
                        renamingFolder = folder
                        isRenamingFolder = true
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        folderToDelete = folder
                        isConfirmingFolderDelete = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                .accessibilityLabel("\(folder.name) options")
            }
            .padding(.horizontal)

            if isExpanded {
                templateGrid(sortOrder.sort(folder.templatesArray))
            }
        }
    }

    private func templateGrid(_ templates: [WorkoutTemplate]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(templates) { template in
                WorkoutTemplateCard(
                    template: template,
                    onTap: { previewingTemplate = template },
                    onEdit: { editingTemplate = template },
                    onRename: {
                        renameText = template.name
                        renamingTemplate = template
                        isRenamingTemplate = true
                    },
                    onDelete: {
                        templateToDelete = template
                        isConfirmingTemplateDelete = true
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No templates yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Create a template to quickly start workouts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func toggle(_ folder: TemplateFolder) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedFolders.contains(folder.id) {
                expandedFolders.remove(folder.id)
            } else {
                expandedFolders.insert(folder.id)
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(PreviewData.shared.modelContainer)
        .environment(LiveWorkoutSession(store: nil, resume: false))
        .environment(PreferencesManager())
}
