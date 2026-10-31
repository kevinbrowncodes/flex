import Foundation
import HealthKit
import Observation
import os

/// The phone's side of the live link (STORY_009): takes the HealthKit workout session the watch
/// mirrors to it and runs a `MirrorPeer` over its data channel, and launches the watch app with a
/// strength-training configuration when a workout starts on the phone. With no Health store
/// (demo launches, previews, no watch) it does nothing and the phone works as it always has.
@MainActor
@Observable
final class PhoneMirrorHost: NSObject {
    let peer: MirrorPeer
    private let healthStore: HKHealthStore?
    private var mirroredSession: HKWorkoutSession?
    private var transport: SessionTransport?
    private static let logger = Logger(subsystem: "kevinbrowncodes.Flex", category: "Mirror")

    init(session: LiveWorkoutSession, healthStore: HKHealthStore?) {
        peer = MirrorPeer(role: .phone, session: session)
        self.healthStore = healthStore
        super.init()
        healthStore?.workoutSessionMirroringStartHandler = { [weak self] mirrored in
            Task { @MainActor in self?.take(mirrored) }
        }
    }

    /// True while the watch is showing the same workout.
    var isLinked: Bool { peer.isLinked }
    var watchHeartRate: Double? { peer.remoteHeartRate }

    /// Asks watchOS to open Flex on the watch for a workout the phone just started; the watch then
    /// mirrors its Health session here and the two sides exchange state.
    func startWatchApp() {
        guard let healthStore, HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        Task {
            do {
                try await healthStore.startWatchApp(toHandle: configuration)
            } catch {
                Self.logger.info("The watch app did not start: \(error.localizedDescription)")
            }
        }
    }

    private func take(_ mirrored: HKWorkoutSession) {
        mirrored.delegate = self
        mirroredSession = mirrored
        let transport = SessionTransport(session: mirrored)
        self.transport = transport
        peer.attach(transport)
        peer.sayHello()
        Self.logger.info("Linked to the watch's workout session")
    }

    private func ended() {
        peer.detach()
        mirroredSession = nil
        transport = nil
    }
}

extension PhoneMirrorHost: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        if toState == .ended {
            Task { @MainActor in self.ended() }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.ended() }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        Task { @MainActor in
            for message in data { self.peer.receive(message) }
        }
    }
}

/// Sends bytes over the mirrored session to the watch.
@MainActor
final class SessionTransport: MirrorTransport {
    private let session: HKWorkoutSession

    init(session: HKWorkoutSession) {
        self.session = session
    }

    func send(_ data: Data) {
        session.sendToRemoteWorkoutSession(data: data) { _, _ in }
    }
}
