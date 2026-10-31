import Foundation
import Observation

/// What the watch knows: the latest snapshot the phone sent, kept on disk so a relaunched watch app
/// shows it with no phone in reach (STORY_005). Each snapshot also leaves this week's count in the
/// App Group for the watch-face complication (STORY_011).
@MainActor
@Observable
final class WatchState {
    private(set) var snapshot: WatchSnapshot?
    private let store: JSONFileStore<WatchSnapshot>?
    private let sharedDefaults: UserDefaults?
    /// Asked to redraw the complication after the shared numbers change; WidgetKit in the app.
    @ObservationIgnored var reloadWidgets: (() -> Void)?

    /// - Parameters:
    ///   - store: where the snapshot is kept; nil keeps it in memory only (demo, previews).
    ///   - initial: a snapshot to start with instead of the stored one (demo, previews).
    ///   - sharedDefaults: the App Group's defaults the complication reads; nil writes nothing.
    init(store: JSONFileStore<WatchSnapshot>?, initial: WatchSnapshot? = nil, sharedDefaults: UserDefaults? = nil) {
        self.store = store
        self.sharedDefaults = sharedDefaults
        snapshot = initial ?? store?.load()
        if let snapshot { share(snapshot) }
    }

    func receive(_ snapshot: WatchSnapshot) {
        self.snapshot = snapshot
        try? store?.save(snapshot)
        share(snapshot)
        reloadWidgets?()
    }

    func clear() {
        snapshot = nil
        store?.clear()
    }

    private func share(_ snapshot: WatchSnapshot) {
        guard let sharedDefaults else { return }
        WeekProgress(snapshot: snapshot).write(to: sharedDefaults)
    }
}
