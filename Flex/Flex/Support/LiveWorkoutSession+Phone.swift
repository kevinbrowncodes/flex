import Foundation
import SwiftData

/// The phone's end of the live workout: finishing saves into SwiftData (STORY_002, STORY_006).
extension LiveWorkoutSession {
    /// Saves the live workout as a `Workout` and ends the session. Throws with the session intact
    /// when the save fails, so nothing is lost.
    @discardableResult
    func finish(into context: ModelContext, at endedAt: Date = Date()) throws -> Workout? {
        guard let workout else { return nil }
        let finished = workout.finished(at: endedAt)
        let saved = try LiveWorkoutBridge.save(finished, into: context)
        endSession()
        onFinish?(finished)
        return saved
    }
}
