import Foundation
import Testing
@testable import FlexWatch

/// Finished workouts leave the watch for the phone, and the watch says where each stands (STORY_007).
@MainActor
struct OutboxTests {
    /// A WatchConnectivity stand-in: remembers sends, holds transfers in flight until told otherwise.
    final class FakeTransport: WatchTransport {
        var sent: [FinishedWorkout] = []
        var inFlightIDs: Set<UUID> = []
        var refuses = false
        struct Refused: Error {}

        func send(_ finished: FinishedWorkout) throws {
            if refuses { throw Refused() }
            sent.append(finished)
            inFlightIDs.insert(finished.workout.id)
        }
    }

    private func finished(_ title: String) -> FinishedWorkout {
        let start = Date(timeIntervalSinceReferenceDate: 814_000_000)
        let live = LiveWorkout(title: title, startedAt: start, exercises: [
            LiveExercise(name: "Dip", bodyPart: "Chest", sets: [LiveSet(reps: 10, isCompleted: true)])
        ])
        return live.finished(at: start.addingTimeInterval(600))
    }

    @Test("Finishing sends one transfer; completion empties the outbox and marks it delivered")
    func enqueueAndComplete() {
        let outbox = WatchOutbox(store: nil)
        let transport = FakeTransport()
        let delivery = WatchDelivery(outbox: outbox, transport: transport)
        let workout = finished("Push")

        delivery.enqueue(workout)
        #expect(transport.sent == [workout])
        #expect(delivery.pendingCount == 1)
        #expect(delivery.status(of: workout.workout.id) == .pending)

        delivery.completed(id: workout.workout.id, failed: false)
        #expect(delivery.pendingCount == 0)
        #expect(delivery.status(of: workout.workout.id) == .delivered)
    }

    @Test("A failed transfer stays pending and goes again on the next flush")
    func failureKeepsPending() {
        let outbox = WatchOutbox(store: nil)
        let transport = FakeTransport()
        let delivery = WatchDelivery(outbox: outbox, transport: transport)
        let workout = finished("Pull")

        delivery.enqueue(workout)
        transport.inFlightIDs = [] // the system gave up on it
        delivery.completed(id: workout.workout.id, failed: true)
        #expect(delivery.pendingCount == 1)
        #expect(delivery.status(of: workout.workout.id) == .pending)

        delivery.flush()
        #expect(transport.sent.count == 2)
    }

    @Test("Flush re-sends what is pending and not in flight, and nothing that is")
    func flushRespectsInFlight() {
        let outbox = WatchOutbox(store: nil)
        let transport = FakeTransport()
        let delivery = WatchDelivery(outbox: outbox, transport: transport)
        let inFlight = finished("Legs")
        let stranded = finished("Arms")
        outbox.add(inFlight)
        outbox.add(stranded)
        transport.inFlightIDs = [inFlight.workout.id]

        delivery.flush()

        #expect(transport.sent == [stranded])
        #expect(delivery.status(of: inFlight.workout.id) == .pending)
        #expect(delivery.status(of: stranded.workout.id) == .pending)
    }

    @Test("With no transport (a demo launch) everything stays pending; a refusing one too")
    func noTransport() {
        let outbox = WatchOutbox(store: nil)
        let delivery = WatchDelivery(outbox: outbox)
        let workout = finished("Push")
        delivery.enqueue(workout)
        #expect(delivery.status(of: workout.workout.id) == .pending)
        #expect(delivery.pendingCount == 1)

        let transport = FakeTransport()
        transport.refuses = true
        delivery.attach(transport)
        delivery.flush()
        #expect(transport.sent.isEmpty)
        #expect(delivery.status(of: workout.workout.id) == .pending)
    }

    @Test("A workout not in the outbox and never seen counts as delivered")
    func unknownIsDelivered() {
        let delivery = WatchDelivery(outbox: WatchOutbox(store: nil))
        #expect(delivery.status(of: UUID()) == .delivered)
    }
}
