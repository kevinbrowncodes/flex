import Foundation

/// The rest-timer default: what Settings offers, how it reads, and how a stored value is taken
/// (STORY_003). The running countdown itself is `LiveRest` on the live workout.
enum RestTimer {
    static let defaultSeconds: TimeInterval = 90

    /// Off, then 0:30 up to 5:00.
    static let options: [TimeInterval] = [0, 30, 45, 60, 90, 120, 150, 180, 240, 300]

    /// "Off", "0:45", "1:30".
    static func label(_ seconds: TimeInterval) -> String {
        seconds <= 0 ? "Off" : Formatting.timer(seconds)
    }

    /// A stored preference (a number from the key-value store), or the default when none is stored.
    /// Zero is a real choice (off), so only a missing value falls back.
    static func seconds(stored: Any?) -> TimeInterval {
        guard let number = stored as? NSNumber else { return defaultSeconds }
        return max(0, number.doubleValue)
    }
}
