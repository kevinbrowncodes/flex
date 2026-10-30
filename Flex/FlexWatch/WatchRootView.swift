import SwiftUI

/// The watch app's first screen. Until the phone has sent a snapshot (STORY_005) there is nothing
/// to start, so it says how to get one (STORY_004).
struct WatchRootView: View {
    var body: some View {
        NavigationStack {
            WaitingForPhoneView()
                .navigationTitle("Flex")
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

#Preview {
    WatchRootView()
}
