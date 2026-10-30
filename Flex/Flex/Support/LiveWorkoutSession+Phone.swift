import Foundation
import SwiftData

/// The phone's end of the live workout: finishing saves into SwiftData (STORY_002, STORY_006).
extension LiveWorkoutSession {
    /// Saves the live workout as a `Workout` and ends the session. Throws with the session intact
    /// when the save fails, so nothing is lost.
    @discardableResult
    func finish(into context: ModelContext, at endedAt: Date = Date()) throws -> Workout? {
        guard let workout else { return nil }
        let saved = try LiveWorkoutBridge.save(workout.finished(at: endedAt), into: context)
        discard()
        return saved
    }
}
