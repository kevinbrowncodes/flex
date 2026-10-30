import Foundation
import SwiftData
import WatchConnectivity
import os

/// The phone's end of WatchConnectivity (STORY_005): sends the watch its snapshot when the
/// session comes up, when Flex comes to the foreground, and after anything it holds changes
/// (a SwiftData save, a preference). The phone is the only writer; until STORY_007 nothing comes
/// back. On a device with no watch support (iPad) it does nothing.
@MainActor
final class PhoneWatchLink: NSObject {
    private let makeSnapshot: @MainActor () throws -> WatchSnapshot
    private var lastSent: WatchSnapshot?
    private var pending: Task<Void, Never>?
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "WatchLink")

    init(makeSnapshot: @escaping @MainActor () throws -> WatchSnapshot) {
        self.makeSnapshot = makeSnapshot
        super.init()
        let center = NotificationCenter.default
        for name in [ModelContext.didSave, PreferencesManager.didChange] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.scheduleSend() }
            }
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Sends after a short quiet period, so a burst of saves is one transfer.
    func scheduleSend(after delay: TimeInterval = 1) {
        pending?.cancel()
        pending = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            self?.sendNow()
        }
    }

    /// Builds and sends the snapshot now, unless nothing in it changed since the last send.
    func sendNow() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        do {
            let snapshot = try makeSnapshot()
            if let lastSent, lastSent.sameContent(as: snapshot) { return }
            let data = try FlexJSON.encoder.encode(snapshot)
            try session.updateApplicationContext([WatchSnapshot.contextKey: data])
            self.lastSent = snapshot
            Self.logger.info("Sent the watch a snapshot: \(snapshot.allTemplates.count) templates")
        } catch {
            Self.logger.error("Could not send the watch its snapshot: \(error.localizedDescription)")
        }
    }
}

extension PhoneWatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.scheduleSend(after: 0) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // The user switched watches; the session must be activated again for the new one.
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.scheduleSend(after: 0) }
    }
}
