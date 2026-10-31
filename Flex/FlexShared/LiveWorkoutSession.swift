import Foundation
import Observation

/// The workout in progress on this device: holds the `LiveWorkout`, applies edits, and keeps it on
/// disk after each one so a closed app resumes where it left off (STORY_002). Device-neutral: the
/// phone adds saving into SwiftData as an extension (STORY_006), the watch hands the finished
/// workout to its outbox. The callbacks let the live link between the devices follow along
/// (STORY_009).
@MainActor
@Observable
final class LiveWorkoutSession {
    private(set) var workout: LiveWorkout?
    private let store: LiveWorkoutStore?
    /// The last failure to write the live workout to disk; the session keeps going regardless.
    private(set) var lastPersistError: String?

    /// After an edit was applied here, with the time it was applied at.
    @ObservationIgnored var onApplied: ((LiveWorkoutEdit, Date) -> Void)?
    /// After the workout was finished here (and, on the phone, saved).
    @ObservationIgnored var onFinish: ((FinishedWorkout) -> Void)?
    /// After a live workout was discarded here.
    @ObservationIgnored var onDiscard: (() -> Void)?

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

    /// Starts a workout, or replaces the one running with a copy from the other device.
    func start(_ workout: LiveWorkout) {
        self.workout = workout
        persist()
    }

    func apply(_ edit: LiveWorkoutEdit, at date: Date = Date()) {
        guard workout != nil else { return }
        workout?.apply(edit, at: date)
        persist()
        onApplied?(edit, date)
    }

    /// Ends the session and returns the finished workout (empty sets dropped); nil when none is live.
    func finish(at endedAt: Date = Date()) -> FinishedWorkout? {
        guard let workout else { return nil }
        let finished = workout.finished(at: endedAt)
        endSession()
        onFinish?(finished)
        return finished
    }

    /// Ends the session without saving.
    func discard() {
        let hadWorkout = workout != nil
        endSession()
        if hadWorkout {
            onDiscard?()
        }
    }

    /// Forgets the live workout here and on disk. The phone's `finish(into:)` calls it after saving.
    func endSession() {
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
