import SwiftUI

/// The watch app's first screen: the home once the phone has sent a snapshot (STORY_005), and
/// until then how to get one (STORY_004).
struct WatchRootView: View {
    @Environment(WatchState.self) private var state

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = state.snapshot {
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
}

#if DEBUG
#Preview("With a snapshot") {
    WatchRootView()
        .environment(WatchState(store: nil, initial: .sample))
}
#endif
