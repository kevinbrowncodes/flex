import Foundation

/// The one key two devices agree on for "the same exercise". `Exercise` has no id, and
/// `ExerciseLibrary` already merges duplicates on this key, so a live workout names its exercises
/// and the phone resolves them when it saves (STORY_002).
enum ExerciseName {
    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
