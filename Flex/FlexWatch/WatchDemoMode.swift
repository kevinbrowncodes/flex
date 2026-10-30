import Foundation

#if DEBUG
/// The watch's side of the `FLEX_DEMO` launch hook (see `DemoLaunch`): UI tests and screenshots
/// launch into known state with no phone. Compiled out of Release (STORY_004).
struct WatchDemoMode: Sendable {
    typealias Dataset = DemoLaunch.Dataset

    let dataset: Dataset
    /// `FLEX_DEMO_RESUME=1` keeps a live workout saved by an earlier launch.
    let resumesLiveWorkout: Bool

    static let current = WatchDemoMode(environment: ProcessInfo.processInfo.environment)

    init?(environment: [String: String]) {
        guard let dataset = DemoLaunch.dataset(in: environment) else {
            return nil
        }
        self.dataset = dataset
        resumesLiveWorkout = DemoLaunch.resumesLiveWorkout(in: environment)
    }
}
#endif
