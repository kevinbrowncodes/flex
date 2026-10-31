import Foundation
import Observation

/// What delivery needs from WatchConnectivity, so the logic runs against a fake in tests (STORY_007).
@MainActor
protocol WatchTransport: AnyObject {
    /// Queues a finished workout for the phone; the system delivers it when the phone is reachable.
    func send(_ finished: FinishedWorkout) throws
    /// The ids of finished workouts whose transfer the system still holds.
    var inFlightIDs: Set<UUID> { get }
}

/// Gets every finished workout in the outbox to the phone, and says where each one stands
/// (STORY_007). A transfer that completes removes its workout from the outbox; one that fails stays
/// and goes again on the next flush.
@MainActor
@Observable
final class WatchDelivery {
    enum Status: Equatable {
        case pending
        case delivered
    }

    private let outbox: WatchOutbox
    private weak var transport: WatchTransport?
    /// What happened to each workout finished since launch.
    private(set) var statuses: [UUID: Status] = [:]

    init(outbox: WatchOutbox, transport: WatchTransport? = nil) {
        self.outbox = outbox
        self.transport = transport
    }

    func attach(_ transport: WatchTransport) {
        self.transport = transport
    }

    var pendingCount: Int { outbox.pending.count }

    /// Keeps the finished workout and sends it.
    func enqueue(_ finished: FinishedWorkout) {
        outbox.add(finished)
        statuses[finished.workout.id] = .pending
        flush()
    }

    /// Sends every pending workout the system is not already carrying.
    func flush() {
        guard let transport else { return }
        let inFlight = transport.inFlightIDs
        for finished in outbox.pending where !inFlight.contains(finished.workout.id) {
            try? transport.send(finished)
            statuses[finished.workout.id] = .pending
        }
    }

    /// The system finished a transfer: delivered, or failed and still pending.
    func completed(id: UUID, failed: Bool) {
        if failed {
            statuses[id] = .pending
        } else {
            outbox.remove(id: id)
            statuses[id] = .delivered
        }
    }

    func status(of id: UUID) -> Status {
        if let status = statuses[id] { return status }
        return outbox.pending.contains { $0.workout.id == id } ? .pending : .delivered
    }
}
