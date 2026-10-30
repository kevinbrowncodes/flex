import Foundation
import Observation

/// The workout in progress on this device: holds the `LiveWorkout`, applies edits, and keeps it on
/// disk after each one so a closed app resumes where it left off (STORY_002). Device-neutral: the
/// phone adds saving into SwiftData as an extension (STORY_006), the watch hands the finished
/// workout to its outbox.
@MainActor
@Observable
final class LiveWorkoutSession {
    private(set) var workout: LiveWorkout?
    private let store: LiveWorkoutStore?
    /// The last failure to write the live workout to disk; the session keeps going regardless.
    private(set) var lastPersistError: String?

    /// - Parameters:
    ///   - store: where the live workout is kept; nil keeps it in memory only (previews).
    ///   - resume: load a saved workout at start. False clears one left behind (demo launches).
    init(store: LiveWorkoutStore?, resume: Bool = true) {
        self.store = store
        if resume {
            workout = store?.load()
        } else {
            store?.clear()
        }
    }

    var isActive: Bool { workout != nil }

    func start(_ workout: LiveWorkout) {
        self.workout = workout
        persist()
    }

    func apply(_ edit: LiveWorkoutEdit) {
        guard workout != nil else { return }
        workout?.apply(edit)
        persist()
    }

    /// Ends the session and returns the finished workout (empty sets dropped); nil when none is live.
    func finish(at endedAt: Date = Date()) -> FinishedWorkout? {
        guard let workout else { return nil }
        let finished = workout.finished(at: endedAt)
        discard()
        return finished
    }

    /// Ends the session without saving.
    func discard() {
        workout = nil
        store?.clear()
    }

    private func persist() {
        guard let workout else { return }
        do {
            try store?.save(workout)
            lastPersistError = nil
        } catch {
            lastPersistError = error.localizedDescription
        }
    }
}
