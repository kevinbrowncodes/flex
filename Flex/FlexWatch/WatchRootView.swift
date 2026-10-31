import SwiftUI

/// The watch app's first screen: the workout in progress when there is one (STORY_006), the home
/// once the phone has sent a snapshot (STORY_005), and until then how to get one (STORY_004).
struct WatchRootView: View {
    @Environment(WatchState.self) private var state
    @Environment(LiveWorkoutSession.self) private var session
    @Environment(WatchHealthSession.self) private var health
    @Environment(WatchDelivery.self) private var delivery
    @Environment(MirrorPeer.self) private var mirror
    @State private var path = NavigationPath()
    /// The workout just finished, shown until Done.
    @State private var justFinished: FinishedWorkout?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let finished = justFinished {
                    WatchFinishedView(finished: finished) { justFinished = nil }
                } else if session.isActive {
                    WatchWorkoutView { justFinished = $0 }
                } else if let snapshot = state.snapshot {
                    WatchHomeView(snapshot: snapshot)
                } else {
                    WaitingForPhoneView()
                        .navigationTitle("Flex")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let template = state.snapshot?.template(withID: id) {
                    WatchTemplateView(template: template)
                }
            }
        }
        // Starting a workout from a pushed template screen pops back so the workout is the root, and
        // the Health workout starts with it (STORY_008); finish and discard end it where they happen.
        .onChange(of: session.isActive) { _, isActive in
            if isActive {
                path = NavigationPath()
                if let workout = session.workout {
                    health.rename(workout.title)
                    Task { await health.begin(title: workout.title, at: workout.startedAt) }
                }
            }
        }
        .task {
            // The phone finished or discarded the shared workout (STORY_009): end here the same way.
            mirror.onRemoteFinish = { endedAt in
                Task { @MainActor in
                    await health.end(at: endedAt)
                    if let finished = session.finish(at: endedAt) {
                        delivery.enqueue(finished)
                        justFinished = finished
                    }
                }
            }
            mirror.onRemoteDiscard = {
                health.discard()
                session.discard()
            }
            // A relaunch with a live workout: the system ended the old Health session, start another.
            if let workout = session.workout, !health.isRunning {
                await health.begin(title: workout.title, at: workout.startedAt)
            }
        }
    }
}

/// "Open Flex on your iPhone to get started."
struct WaitingForPhoneView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image("FlexIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                    Image(systemName: "arrow.right")
                    Image(systemName: "iphone")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

                Text("Open Flex on your iPhone to get started")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("watch-waiting")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

#Preview("Waiting") {
    WatchRootView()
        .environment(WatchState(store: nil))
        .environment(LiveWorkoutSession(store: nil, resume: false))
        .environment(WatchDelivery(outbox: WatchOutbox(store: nil)))
        .environment(WatchHealthSession(store: nil))
        .environment(MirrorPeer(role: .watch, session: LiveWorkoutSession(store: nil, resume: false)))
}

#if DEBUG
#Preview("With a snapshot") {
    WatchRootView()
        .environment(WatchState(store: nil, initial: .sample))
        .environment(LiveWorkoutSession(store: nil, resume: false))
        .environment(WatchDelivery(outbox: WatchOutbox(store: nil)))
        .environment(WatchHealthSession(store: nil))
        .environment(MirrorPeer(role: .watch, session: LiveWorkoutSession(store: nil, resume: false)))
}
#endif
