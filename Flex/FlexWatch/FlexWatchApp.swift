import HealthKit
import SwiftUI
import WatchKit

/// Takes the workout configuration the phone starts the watch app with (STORY_009).
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    nonisolated(unsafe) static var onWorkoutConfiguration: ((HKWorkoutConfiguration) -> Void)?

    func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        Self.onWorkoutConfiguration?(workoutConfiguration)
    }
}

/// Flex on the wrist (EPIC_001). The phone is the only writer of SwiftData and CloudKit; the
/// watch holds plain values from `FlexShared` and what the phone sends it.
@main
struct FlexWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @State private var state: WatchState
    @State private var session: LiveWorkoutSession
    @State private var delivery: WatchDelivery
    /// Apple Health for the workout in progress; no HealthKit in demo launches (STORY_008).
    @State private var health: WatchHealthSession
    /// The live link to the phone, over the mirrored Health session (STORY_009).
    @State private var mirror: MirrorPeer
    /// Takes the phone's snapshot and carries finished workouts back; nil in demo launches,
    /// which carry their own snapshot and never reach a phone (STORY_005, STORY_007).
    @State private var link: WatchLink?

    init() {
        let state: WatchState
        let session: LiveWorkoutSession
        let delivery: WatchDelivery
        let health: WatchHealthSession
        let mirror: MirrorPeer
        var link: WatchLink?

        #if DEBUG
        if let demo = WatchDemoMode.current {
            state = WatchState(store: nil, initial: demo.dataset == .sample ? .sample : nil)
            // The live workout file is real so a relaunch can prove resume; cleared unless asked for.
            session = LiveWorkoutSession(store: .default(), resume: demo.resumesLiveWorkout)
            delivery = WatchDelivery(outbox: WatchOutbox(store: nil))
            mirror = MirrorPeer(role: .watch, session: session)
            health = WatchHealthSession(store: nil, mirror: mirror)
        } else {
            state = WatchState(store: .default(named: "watch-snapshot.json"))
            session = LiveWorkoutSession(store: .default())
            delivery = WatchDelivery(outbox: WatchOutbox(store: .default(named: "finished-workouts.json")))
            mirror = MirrorPeer(role: .watch, session: session)
            health = WatchHealthSession(store: HealthKitStore(), mirror: mirror)
            let realLink = WatchLink(state: state, delivery: delivery)
            delivery.attach(realLink)
            link = realLink
        }
        #else
        state = WatchState(store: .default(named: "watch-snapshot.json"))
        session = LiveWorkoutSession(store: .default())
        delivery = WatchDelivery(outbox: WatchOutbox(store: .default(named: "finished-workouts.json")))
        mirror = MirrorPeer(role: .watch, session: session)
        health = WatchHealthSession(store: HealthKitStore(), mirror: mirror)
        let realLink = WatchLink(state: state, delivery: delivery)
        delivery.attach(realLink)
        link = realLink
        #endif

        // The phone started a workout: open a Health session now, mirrored to the phone, and take
        // the workout itself from the phone's answer to the watch's hello.
        WatchAppDelegate.onWorkoutConfiguration = { _ in
            Task { @MainActor in
                await health.begin(title: LiveWorkout.defaultTitle(for: Date()), at: Date())
            }
        }

        link?.activate()
        _state = State(initialValue: state)
        _session = State(initialValue: session)
        _delivery = State(initialValue: delivery)
        _health = State(initialValue: health)
        _mirror = State(initialValue: mirror)
        _link = State(initialValue: link)
    }

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environment(state)
                .environment(session)
                .environment(delivery)
                .environment(health)
                .environment(mirror)
        }
    }
}
