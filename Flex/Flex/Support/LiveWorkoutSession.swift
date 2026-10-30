import Foundation
import Observation
import SwiftData
import os

/// The workout in progress on this device: holds the `LiveWorkout`, applies edits, and keeps it on
/// disk after each one so a closed app resumes where it left off (STORY_002).
@MainActor
@Observable
final class LiveWorkoutSession {
    private(set) var workout: LiveWorkout?
    private let store: LiveWorkoutStore?
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "LiveWorkout")

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

    /// Saves the live workout as a `Workout` and ends the session. Throws with the session intact
    /// when the save fails, so nothing is lost.
    @discardableResult
    func finish(into context: ModelContext, at endedAt: Date = Date()) throws -> Workout? {
        guard let workout else { return nil }
        let saved = try LiveWorkoutBridge.save(workout.finished(at: endedAt), into: context)
        discard()
        return saved
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
        } catch {
            Self.logger.error("Could not save the live workout: \(error.localizedDescription)")
        }
    }
}
