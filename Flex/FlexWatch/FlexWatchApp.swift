import SwiftUI

/// Flex on the wrist (EPIC_001). The phone is the only writer of SwiftData and CloudKit; the
/// watch holds plain values from `FlexShared` and what the phone sends it.
@main
struct FlexWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}
