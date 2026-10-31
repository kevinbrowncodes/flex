import Foundation
import Testing
@testable import FlexWatch

/// The watch's end of the live link, over a fake Health handle (STORY_009).
@MainActor
struct WatchMirrorTests {
    final class FakeHandle: HealthWorkoutHandle {
        var title = ""
        var onVitals: ((Double?, Double?) -> Void)?
        var onData: ((Data) -> Void)?
        var sent: [Data] = []
        var endedAt: Date?
        var discarded = false
        func send(_ data: Data) { sent.append(data) }
        func end(at end: Date) async throws { endedAt = end }
        func discard() { discarded = true }
    }

    final class FakeStore: HealthStoring {
        var isAvailable = true
        var handles: [FakeHandle] = []
        func requestAuthorization() async throws -> Bool { true }
        func startWorkout(title: String, at start: Date) async throws -> HealthWorkoutHandle {
            let handle = FakeHandle()
            handle.title = title
            handles.append(handle)
            return handle
        }
    }

    private let start = Date(timeIntervalSinceReferenceDate: 814_000_000)

    @Test("Beginning a Health session links the mirror and says hello; a phone edit is applied and answered with state")
    func linkAndEdit() async throws {
        let session = LiveWorkoutSession(store: nil, resume: false)
        let mirror = MirrorPeer(role: .watch, session: session)
        let store = FakeStore()
        let health = WatchHealthSession(store: store, mirror: mirror)
        session.start(LiveWorkout(from: WatchSnapshot.sample.allTemplates[0], at: start, restSeconds: 90))

        await health.begin(title: "Heavy Push", at: start)
        let handle = try #require(store.handles.first)
        #expect(handle.sent.count == 1)
        #expect(try MirrorMessage.decode(handle.sent[0]) == .hello)

        let set = try #require(session.workout?.exercises[0].sets[0])
        handle.onData?(try MirrorMessage.encode(.edit(.setWeight(setID: set.id, weight: 190), at: start.addingTimeInterval(30))))
        #expect(session.workout?.set(withID: set.id)?.weight == 190)
        let answer = try MirrorMessage.decode(try #require(handle.sent.last))
        #expect(answer == .state(try #require(session.workout)))
        #expect(mirror.isLinked)

        handle.onVitals?(128, 40)
        let vitals = try MirrorMessage.decode(try #require(handle.sent.last))
        #expect(vitals == .vitals(heartRate: 128, activeEnergy: 40))

        await health.end(at: start.addingTimeInterval(600))
        #expect(!mirror.isLinked)
    }

    @Test("The watch takes a phone-started workout when it has none, and renames the Health record")
    func adoptsPhoneWorkout() async throws {
        let session = LiveWorkoutSession(store: nil, resume: false)
        let mirror = MirrorPeer(role: .watch, session: session)
        let store = FakeStore()
        let health = WatchHealthSession(store: store, mirror: mirror)
        await health.begin(title: "Workout", at: start)
        let handle = try #require(store.handles.first)

        let fromPhone = LiveWorkout(title: "Leg Day", startedAt: start, exercises: [
            LiveExercise(name: "Squat (Barbell)", bodyPart: "Legs", sets: [LiveSet(reps: 5, weight: 225)])
        ], restSeconds: 60)
        handle.onData?(try MirrorMessage.encode(.state(fromPhone)))
        #expect(session.workout == fromPhone)
        health.rename("Leg Day")
        #expect(handle.title == "Leg Day")

        // The phone finishes: the host ends the watch the same way (here, the callback itself).
        var remoteFinish: Date?
        mirror.onRemoteFinish = { remoteFinish = $0 }
        handle.onData?(try MirrorMessage.encode(.finish(at: start.addingTimeInterval(900))))
        #expect(remoteFinish == start.addingTimeInterval(900))
    }
}
