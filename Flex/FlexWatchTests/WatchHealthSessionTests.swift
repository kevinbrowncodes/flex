import Foundation
import Testing
@testable import FlexWatch

/// The Apple Health side of a watch workout, against a fake HealthKit (STORY_008).
@MainActor
struct WatchHealthSessionTests {
    final class FakeHandle: HealthWorkoutHandle {
        var onVitals: ((Double?, Double?) -> Void)?
        var endedAt: Date?
        var discarded = false
        var failsToEnd = false
        struct Failed: Error {}

        func end(at end: Date) async throws {
            if failsToEnd { throw Failed() }
            endedAt = end
        }

        func discard() { discarded = true }
    }

    final class FakeStore: HealthStoring {
        var isAvailable = true
        var grants = true
        var authorizationRequests = 0
        var started: [(title: String, start: Date)] = []
        var handles: [FakeHandle] = []

        func requestAuthorization() async throws -> Bool {
            authorizationRequests += 1
            return grants
        }

        func startWorkout(title: String, at start: Date) async throws -> HealthWorkoutHandle {
            let handle = FakeHandle()
            started.append((title, start))
            handles.append(handle)
            return handle
        }
    }

    private let start = Date(timeIntervalSinceReferenceDate: 814_000_000)

    @Test("Beginning asks once, starts a session, and vitals flow into the readout")
    func beginAndVitals() async throws {
        let store = FakeStore()
        let health = WatchHealthSession(store: store)
        #expect(health.state == .idle)
        #expect(health.heartRateText == "♥ --")

        await health.begin(title: "Heavy Push", at: start)

        #expect(health.state == .running)
        #expect(health.isRunning)
        #expect(store.authorizationRequests == 1)
        #expect(store.started.count == 1)
        #expect(store.started[0].title == "Heavy Push")
        #expect(store.started[0].start == start)

        let handle = try #require(store.handles.first)
        handle.onVitals?(120, 50)
        handle.onVitals?(130.4, 80)
        #expect(health.heartRate == 130.4)
        #expect(health.heartRateText == "♥ 130")
        #expect(health.activeEnergy == 80)

        await health.begin(title: "Again", at: start) // already running: nothing more starts
        #expect(store.started.count == 1)
    }

    @Test("Ending saves the workout and keeps the average heart rate and energy for the summary")
    func endSaves() async throws {
        let store = FakeStore()
        let health = WatchHealthSession(store: store)
        await health.begin(title: "Heavy Push", at: start)
        let handle = try #require(store.handles.first)
        handle.onVitals?(120, nil)
        handle.onVitals?(130, 300)
        handle.onVitals?(140, 412)

        await health.end(at: start.addingTimeInterval(2700))

        #expect(health.state == .saved)
        #expect(handle.endedAt == start.addingTimeInterval(2700))
        #expect(health.summary == WatchHealthSession.Summary(averageHeartRate: 130, activeEnergy: 412))
        #expect(!health.isRunning)
    }

    @Test("Discarding drops the Health workout with the live one")
    func discard() async throws {
        let store = FakeStore()
        let health = WatchHealthSession(store: store)
        await health.begin(title: "Heavy Push", at: start)
        let handle = try #require(store.handles.first)
        handle.onVitals?(125, 10)

        health.discard()

        #expect(handle.discarded)
        #expect(health.state == .idle)
        #expect(health.heartRate == nil)
        #expect(health.summary == nil)
        #expect(handle.endedAt == nil)
    }

    @Test("Declined, unavailable, or no Health at all: nothing starts and logging is untouched")
    func declinedAndUnavailable() async {
        let denied = FakeStore()
        denied.grants = false
        let deniedHealth = WatchHealthSession(store: denied)
        await deniedHealth.begin(title: "Push", at: start)
        #expect(deniedHealth.state == .denied)
        #expect(denied.started.isEmpty)
        #expect(deniedHealth.heartRateText == "♥ --")

        let unavailable = FakeStore()
        unavailable.isAvailable = false
        let unavailableHealth = WatchHealthSession(store: unavailable)
        await unavailableHealth.begin(title: "Push", at: start)
        #expect(unavailableHealth.state == .unavailable)
        #expect(unavailable.authorizationRequests == 0)

        let none = WatchHealthSession(store: nil)
        await none.begin(title: "Push", at: start)
        #expect(none.state == .unavailable)
        await none.end(at: start)
        #expect(none.summary == nil)
    }

    @Test("A save that fails leaves no summary and does not throw")
    func endFails() async throws {
        let store = FakeStore()
        let health = WatchHealthSession(store: store)
        await health.begin(title: "Push", at: start)
        let handle = try #require(store.handles.first)
        handle.failsToEnd = true

        await health.end(at: start.addingTimeInterval(60))

        #expect(health.state == .unavailable)
        #expect(health.summary == nil)
    }
}
