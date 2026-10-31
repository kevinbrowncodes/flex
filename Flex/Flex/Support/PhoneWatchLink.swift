import Foundation
import SwiftData
import WatchConnectivity
import os

/// The phone's end of WatchConnectivity (STORY_005): sends the watch its snapshot when the
/// session comes up, when Flex comes to the foreground, and after anything it holds changes
/// (a SwiftData save, a preference), and saves the finished workouts the watch sends back
/// (STORY_007). The phone is the only writer. On a device with no watch support (iPad) it does
/// nothing.
@MainActor
final class PhoneWatchLink: NSObject {
    private let makeSnapshot: @MainActor () throws -> WatchSnapshot
    private let saveFinished: @MainActor (FinishedWorkout) throws -> Workout
    private var lastSent: WatchSnapshot?
    private var pending: Task<Void, Never>?
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "WatchLink")

    init(
        makeSnapshot: @escaping @MainActor () throws -> WatchSnapshot,
        saveFinished: @escaping @MainActor (FinishedWorkout) throws -> Workout
    ) {
        self.makeSnapshot = makeSnapshot
        self.saveFinished = saveFinished
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

    /// The finished workout in a user-info transfer from the watch, or nil when it carries none
    /// that decodes.
    nonisolated static func finishedWorkout(in userInfo: [String: Any]) -> FinishedWorkout? {
        guard let data = userInfo[WatchSnapshot.finishedKey] as? Data else { return nil }
        return try? FlexJSON.decoder.decode(FinishedWorkout.self, from: data)
    }

    /// Saves a finished workout the watch sent. The live id makes a second arrival a no-op; a save
    /// that throws is logged, since the watch cannot do anything about it. The save posts
    /// `ModelContext.didSave`, so a fresh snapshot follows by itself.
    @discardableResult
    func receive(_ finished: FinishedWorkout) -> Workout? {
        do {
            let saved = try saveFinished(finished)
            Self.logger.info("Saved a workout from the watch: \(saved.title)")
            return saved
        } catch {
            Self.logger.error("Could not save a workout from the watch: \(error.localizedDescription)")
            return nil
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

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let finished = Self.finishedWorkout(in: userInfo) else { return }
        Task { @MainActor in self.receive(finished) }
    }
}
