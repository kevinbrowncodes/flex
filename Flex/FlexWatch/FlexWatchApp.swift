import SwiftUI

/// Flex on the wrist (EPIC_001). The phone is the only writer of SwiftData and CloudKit; the
/// watch holds plain values from `FlexShared` and what the phone sends it.
@main
struct FlexWatchApp: App {
    @State private var state: WatchState
    /// Takes the phone's snapshot; nil in demo launches, which carry their own (STORY_005).
    @State private var link: WatchLink?

    init() {
        let state: WatchState
        var link: WatchLink?

        #if DEBUG
        if let demo = WatchDemoMode.current {
            state = WatchState(store: nil, initial: demo.dataset == .sample ? .sample : nil)
        } else {
            state = WatchState(store: .default(named: "watch-snapshot.json"))
            link = WatchLink(state: state)
        }
        #else
        state = WatchState(store: .default(named: "watch-snapshot.json"))
        link = WatchLink(state: state)
        #endif

        link?.activate()
        _state = State(initialValue: state)
        _link = State(initialValue: link)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(state)
        }
    }
}
