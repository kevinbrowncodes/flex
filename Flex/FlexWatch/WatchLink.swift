import Foundation
import WatchConnectivity
import os

/// The watch's end of WatchConnectivity (STORY_005): takes the phone's snapshot, both the one
/// delivered while running and the last one the system kept while the app was closed.
@MainActor
final class WatchLink: NSObject {
    private let state: WatchState
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "WatchLink")

    init(state: WatchState) {
        self.state = state
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func take(_ data: Data?) {
        guard let data else { return }
        do {
            let snapshot = try FlexJSON.decoder.decode(WatchSnapshot.self, from: data)
            state.receive(snapshot)
            Self.logger.info("Took a snapshot from the phone: \(snapshot.allTemplates.count) templates")
        } catch {
            Self.logger.error("Could not read the phone's snapshot: \(error.localizedDescription)")
        }
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let data = session.receivedApplicationContext[WatchSnapshot.contextKey] as? Data
        Task { @MainActor in self.take(data) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[WatchSnapshot.contextKey] as? Data
        Task { @MainActor in self.take(data) }
    }
}
