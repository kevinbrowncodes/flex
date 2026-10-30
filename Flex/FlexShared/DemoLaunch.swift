import Foundation

/// The launch-environment hook UI tests and screenshots use, read the same way on every device
/// (STORY_004). The phone's `DemoMode` and the watch's `WatchDemoMode` both parse through here.
///
/// - `FLEX_DEMO=sample` (or `1`): realistic sample data, signed in, welcome dismissed.
/// - `FLEX_DEMO=empty`: only the bundled exercise library.
/// - `FLEX_DEMO_RESUME=1`: keep a live workout saved by an earlier launch instead of starting clean.
enum DemoLaunch {
    enum Dataset: Sendable {
        case sample
        case empty
    }

    static func dataset(in environment: [String: String]) -> Dataset? {
        guard let value = environment["FLEX_DEMO"]?.lowercased(), !value.isEmpty, value != "0" else {
            return nil
        }
        return value == "empty" ? .empty : .sample
    }

    static func resumesLiveWorkout(in environment: [String: String]) -> Bool {
        ["1", "true", "yes"].contains(environment["FLEX_DEMO_RESUME"]?.lowercased() ?? "")
    }
}
