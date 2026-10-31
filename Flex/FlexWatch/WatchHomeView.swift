import SwiftUI

/// The watch home once a snapshot has arrived: folders as sections, their templates, the unfiled
/// templates, and this week's count in the toolbar (STORY_005).
struct WatchHomeView: View {
    let snapshot: WatchSnapshot

    var body: some View {
        List {
            ForEach(snapshot.folders) { folder in
                Section(folder.name) {
                    ForEach(folder.templates) { template in
                        templateRow(template)
                    }
                }
            }
            if !snapshot.templates.isEmpty {
                Section("Templates") {
                    ForEach(snapshot.templates) { template in
                        templateRow(template)
                    }
                }
            }
        }
        .navigationTitle("Flex")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(snapshot.workoutsThisWeek)/\(snapshot.weeklyTarget)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(snapshot.workoutsThisWeek >= snapshot.weeklyTarget ? .green : .secondary)
                    .accessibilityLabel("\(snapshot.workoutsThisWeek) of \(snapshot.weeklyTarget) workouts this week")
                    .accessibilityIdentifier("watch-week")
            }
        }
    }

    private func templateRow(_ template: SnapshotTemplate) -> some View {
        NavigationLink(value: template.id) {
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.headline)
                Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("watch-template-\(template.name)")
    }
}

/// One template: Start, then its exercises, their planned set counts, and what was lifted last time.
struct WatchTemplateView: View {
    @Environment(WatchState.self) private var state
    @Environment(LiveWorkoutSession.self) private var session
    let template: SnapshotTemplate

    var body: some View {
        List {
            Button {
                let restSeconds = state.snapshot?.restSeconds ?? RestTimer.defaultSeconds
                var start = Date()
                #if DEBUG
                start = start.addingTimeInterval(WatchDemoMode.current?.workoutStartOffset ?? 0)
                #endif
                session.start(LiveWorkout(from: template, at: start, restSeconds: restSeconds))
            } label: {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier("watch-start")

            ForEach(template.exercises, id: \.name) { exercise in
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("\(exercise.plannedSets.count) set\(exercise.plannedSets.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("last \(exercise.lastSummary ?? "—")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("watch-last-\(exercise.name)")
                }
            }
        }
        .navigationTitle(template.name)
    }
}

#if DEBUG
#Preview("Home") {
    NavigationStack {
        WatchHomeView(snapshot: .sample)
    }
}

#Preview("Template") {
    NavigationStack {
        WatchTemplateView(template: WatchSnapshot.sample.allTemplates[0])
    }
    .environment(WatchState(store: nil, initial: .sample))
    .environment(LiveWorkoutSession(store: nil, resume: false))
}
#endif
