import Foundation
import Observation

/// Finished workouts the watch still has to hand to the phone (STORY_006). Kept on disk so a
/// workout finished with the phone in the locker survives until they meet; STORY_007 delivers.
@MainActor
@Observable
final class WatchOutbox {
    private(set) var pending: [FinishedWorkout]
    private let store: JSONFileStore<[FinishedWorkout]>?

    init(store: JSONFileStore<[FinishedWorkout]>?) {
        self.store = store
        pending = store?.load() ?? []
    }

    func add(_ finished: FinishedWorkout) {
        guard !pending.contains(where: { $0.workout.id == finished.workout.id }) else { return }
        pending.append(finished)
        persist()
    }

    func remove(id: UUID) {
        pending.removeAll { $0.workout.id == id }
        persist()
    }

    private func persist() {
        try? store?.save(pending)
    }
}
