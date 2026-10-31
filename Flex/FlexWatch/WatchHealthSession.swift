import Foundation
import HealthKit
import Observation

/// What the Health session needs from HealthKit, so the controller is tested with a fake (STORY_008).
@MainActor
protocol HealthStoring: AnyObject {
    var isAvailable: Bool { get }
    /// Asks once for what Flex needs; true when workouts may be written.
    func requestAuthorization() async throws -> Bool
    /// Starts a strength-training workout session and its builder.
    func startWorkout(title: String, at start: Date) async throws -> HealthWorkoutHandle
}

/// A running Health workout: vitals as they arrive, then end and save, or discard.
@MainActor
protocol HealthWorkoutHandle: AnyObject {
    var onVitals: ((_ heartRate: Double?, _ activeEnergy: Double?) -> Void)? { get set }
    func end(at end: Date) async throws
    func discard()
}

/// Runs the Apple Health side of a watch workout (STORY_008): asks for authorization the first
/// time, keeps a workout session going while a live workout runs (which also keeps Flex on the
/// screen when the wrist drops), publishes heart rate and active energy, and saves the workout
/// when the live workout finishes. Declined or unavailable Health changes nothing about logging.
@MainActor
@Observable
final class WatchHealthSession {
    enum State: Equatable {
        case idle
        case unavailable
        case denied
        case running
        case saved
    }

    struct Summary: Equatable {
        var averageHeartRate: Double?
        var activeEnergy: Double?
    }

    private(set) var state: State = .idle
    private(set) var heartRate: Double?
    private(set) var activeEnergy: Double?
    private(set) var summary: Summary?
    private let store: HealthStoring?
    private var handle: HealthWorkoutHandle?
    private var heartRateSamples: [Double] = []

    /// - Parameter store: HealthKit, or nil where there is none (demo launches, previews).
    init(store: HealthStoring?) {
        self.store = store
    }

    var isRunning: Bool { state == .running }

    /// "♥ 128", or "♥ --" with no reading.
    var heartRateText: String {
        heartRate.map { "♥ \(Int($0.rounded()))" } ?? "♥ --"
    }

    /// Starts the Health workout for a live workout that just began. Nothing when one already runs.
    func begin(title: String, at start: Date) async {
        guard state != .running, let store, store.isAvailable else {
            if state != .running { state = .unavailable }
            return
        }
        do {
            guard try await store.requestAuthorization() else {
                state = .denied
                return
            }
            let handle = try await store.startWorkout(title: title, at: start)
            handle.onVitals = { [weak self] heartRate, activeEnergy in
                self?.take(heartRate: heartRate, activeEnergy: activeEnergy)
            }
            self.handle = handle
            heartRateSamples = []
            heartRate = nil
            activeEnergy = nil
            summary = nil
            state = .running
        } catch {
            state = .unavailable
        }
    }

    private func take(heartRate: Double?, activeEnergy: Double?) {
        if let heartRate {
            self.heartRate = heartRate
            heartRateSamples.append(heartRate)
        }
        if let activeEnergy {
            self.activeEnergy = activeEnergy
        }
    }

    /// Ends the Health workout and saves it, keeping the summary for the finish screen.
    func end(at end: Date) async {
        guard let handle, state == .running else { return }
        let average = heartRateSamples.isEmpty ? nil : heartRateSamples.reduce(0, +) / Double(heartRateSamples.count)
        do {
            try await handle.end(at: end)
            summary = Summary(averageHeartRate: average, activeEnergy: activeEnergy)
            state = .saved
        } catch {
            state = .unavailable
        }
        self.handle = nil
    }

    /// Drops the Health workout with the live one.
    func discard() {
        handle?.discard()
        handle = nil
        heartRateSamples = []
        heartRate = nil
        activeEnergy = nil
        summary = nil
        state = .idle
    }
}

// MARK: - HealthKit

/// HealthKit as `HealthStoring`: a traditional strength-training session with a live builder.
@MainActor
final class HealthKitStore: HealthStoring {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws -> Bool {
        let share: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        let read: Set<HKObjectType> = [HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned)]
        try await store.requestAuthorization(toShare: share, read: read)
        return store.authorizationStatus(for: HKWorkoutType.workoutType()) == .sharingAuthorized
    }

    func startWorkout(title: String, at start: Date) async throws -> HealthWorkoutHandle {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
        let handle = HealthKitWorkout(session: session, builder: builder, title: title)
        session.startActivity(with: start)
        try await builder.beginCollection(at: start)
        return handle
    }
}

@MainActor
final class HealthKitWorkout: NSObject, HealthWorkoutHandle {
    private let session: HKWorkoutSession
    private let builder: HKLiveWorkoutBuilder
    private let title: String
    var onVitals: ((Double?, Double?) -> Void)?

    init(session: HKWorkoutSession, builder: HKLiveWorkoutBuilder, title: String) {
        self.session = session
        self.builder = builder
        self.title = title
        super.init()
        builder.delegate = self
    }

    func end(at end: Date) async throws {
        session.end()
        try await builder.endCollection(at: end)
        try await builder.addMetadata([HKMetadataKeyWorkoutBrandName: "Flex", "FlexWorkoutTitle": title])
        _ = try await builder.finishWorkout()
    }

    func discard() {
        session.end()
        builder.discardWorkout()
    }
}

extension HealthKitWorkout: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let heartRate = workoutBuilder.statistics(for: HKQuantityType(.heartRate))?
            .mostRecentQuantity()?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let energy = workoutBuilder.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?
            .doubleValue(for: .kilocalorie())
        Task { @MainActor in self.onVitals?(heartRate, energy) }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
