import SwiftUI

/// The watch app's first screen: the workout in progress when there is one (STORY_006), the home
/// once the phone has sent a snapshot (STORY_005), and until then how to get one (STORY_004).
struct WatchRootView: View {
    @Environment(WatchState.self) private var state
    @Environment(LiveWorkoutSession.self) private var session
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
        // Starting a workout from a pushed template screen pops back so the workout is the root.
        .onChange(of: session.isActive) { _, isActive in
            if isActive { path = NavigationPath() }
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
        .environment(WatchOutbox(store: nil))
}

#if DEBUG
#Preview("With a snapshot") {
    WatchRootView()
        .environment(WatchState(store: nil, initial: .sample))
        .environment(LiveWorkoutSession(store: nil, resume: false))
        .environment(WatchOutbox(store: nil))
}
#endif
