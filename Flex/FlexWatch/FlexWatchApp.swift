import SwiftUI

/// Flex on the wrist (EPIC_001). The phone is the only writer of SwiftData and CloudKit; the
/// watch holds plain values from `FlexShared` and what the phone sends it.
@main
struct FlexWatchApp: App {
    @State private var state: WatchState
    @State private var session: LiveWorkoutSession
    @State private var delivery: WatchDelivery
    /// Takes the phone's snapshot and carries finished workouts back; nil in demo launches,
    /// which carry their own snapshot and never reach a phone (STORY_005, STORY_007).
    @State private var link: WatchLink?

    init() {
        let state: WatchState
        let session: LiveWorkoutSession
        let delivery: WatchDelivery
        var link: WatchLink?

        #if DEBUG
        if let demo = WatchDemoMode.current {
            state = WatchState(store: nil, initial: demo.dataset == .sample ? .sample : nil)
            // The live workout file is real so a relaunch can prove resume; cleared unless asked for.
            session = LiveWorkoutSession(store: .default(), resume: demo.resumesLiveWorkout)
            delivery = WatchDelivery(outbox: WatchOutbox(store: nil))
        } else {
            state = WatchState(store: .default(named: "watch-snapshot.json"))
            session = LiveWorkoutSession(store: .default())
            delivery = WatchDelivery(outbox: WatchOutbox(store: .default(named: "finished-workouts.json")))
            let realLink = WatchLink(state: state, delivery: delivery)
            delivery.attach(realLink)
            link = realLink
        }
        #else
        state = WatchState(store: .default(named: "watch-snapshot.json"))
        session = LiveWorkoutSession(store: .default())
        delivery = WatchDelivery(outbox: WatchOutbox(store: .default(named: "finished-workouts.json")))
        let realLink = WatchLink(state: state, delivery: delivery)
        delivery.attach(realLink)
        link = realLink
        #endif

        link?.activate()
        _state = State(initialValue: state)
        _session = State(initialValue: session)
        _delivery = State(initialValue: delivery)
        _link = State(initialValue: link)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(state)
                .environment(session)
                .environment(delivery)
        }
    }
}
