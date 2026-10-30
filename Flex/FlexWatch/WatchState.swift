import Foundation
import Observation

/// What the watch knows: the latest snapshot the phone sent, kept on disk so a relaunched watch app
/// shows it with no phone in reach (STORY_005).
@MainActor
@Observable
final class WatchState {
    private(set) var snapshot: WatchSnapshot?
    private let store: JSONFileStore<WatchSnapshot>?

    /// - Parameters:
    ///   - store: where the snapshot is kept; nil keeps it in memory only (demo, previews).
    ///   - initial: a snapshot to start with instead of the stored one (demo, previews).
    init(store: JSONFileStore<WatchSnapshot>?, initial: WatchSnapshot? = nil) {
        self.store = store
        snapshot = initial ?? store?.load()
    }

    func receive(_ snapshot: WatchSnapshot) {
        self.snapshot = snapshot
        try? store?.save(snapshot)
    }

    func clear() {
        snapshot = nil
        store?.clear()
    }
}
