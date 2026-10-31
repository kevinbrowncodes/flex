import Foundation
import WatchConnectivity
import os

/// The watch's end of WatchConnectivity: takes the phone's snapshot (STORY_005), both the one
/// delivered while running and the last one the system kept while the app was closed, and carries
/// finished workouts back as queued user-info transfers (STORY_007).
@MainActor
final class WatchLink: NSObject {
    private let state: WatchState
    private let delivery: WatchDelivery
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "WatchLink")

    init(state: WatchState, delivery: WatchDelivery) {
        self.state = state
        self.delivery = delivery
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

extension WatchLink: WatchTransport {
    struct NotActivated: Error {}

    func send(_ finished: FinishedWorkout) throws {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated else { throw NotActivated() }
        let data = try FlexJSON.encoder.encode(finished)
        session.transferUserInfo([
            WatchSnapshot.finishedKey: data,
            WatchSnapshot.finishedIDKey: finished.workout.id.uuidString
        ])
        Self.logger.info("Queued a finished workout for the phone")
    }

    var inFlightIDs: Set<UUID> {
        guard WCSession.isSupported() else { return [] }
        return Set(WCSession.default.outstandingUserInfoTransfers.compactMap {
            ($0.userInfo[WatchSnapshot.finishedIDKey] as? String).flatMap(UUID.init)
        })
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let data = session.receivedApplicationContext[WatchSnapshot.contextKey] as? Data
        Task { @MainActor in
            self.take(data)
            self.delivery.flush()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[WatchSnapshot.contextKey] as? Data
        Task { @MainActor in self.take(data) }
    }

    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        let id = (userInfoTransfer.userInfo[WatchSnapshot.finishedIDKey] as? String).flatMap(UUID.init)
        let failed = error != nil
        Task { @MainActor in
            if let id { self.delivery.completed(id: id, failed: failed) }
        }
    }
}
