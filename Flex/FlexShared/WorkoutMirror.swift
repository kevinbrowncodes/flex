import Foundation
import Observation

/// What the phone and the watch say to each other over the mirrored workout session's data channel
/// while they show the same workout (STORY_009). The watch is the source of truth: it applies every
/// edit, its own and the phone's, and answers each with its whole state; the phone applies its own
/// edit at once for responsiveness and adopts every state that is not older than its own.
enum MirrorMessage: Codable, Equatable, Sendable {
    /// A side joined the link; the other answers with its state when it has a workout.
    case hello
    /// The whole live workout, as the sender holds it.
    case state(LiveWorkout)
    /// One edit, with the time it was applied.
    case edit(LiveWorkoutEdit, at: Date)
    /// The watch's readings, for the phone to show.
    case vitals(heartRate: Double?, activeEnergy: Double?)
    /// The sender finished the workout at that time; the receiver finishes too.
    case finish(at: Date)
    /// The sender discarded the workout; the receiver discards too.
    case discard

    static func encode(_ message: MirrorMessage) throws -> Data {
        try FlexJSON.encoder.encode(message)
    }

    static func decode(_ data: Data) throws -> MirrorMessage {
        try FlexJSON.decoder.decode(MirrorMessage.self, from: data)
    }
}

/// What a peer needs to reach the other device: a way to send bytes. The real one is the HealthKit
/// mirrored session; tests wire two fakes together.
@MainActor
protocol MirrorTransport: AnyObject {
    func send(_ data: Data)
}

/// One side of the live link between the phone and the watch (STORY_009). It watches the local
/// `LiveWorkoutSession` for edits, finish and discard and tells the other side; it takes the other
/// side's messages and applies them to the local session.
@MainActor
@Observable
final class MirrorPeer {
    enum Role: Equatable {
        case watch
        case phone
    }

    let role: Role
    @ObservationIgnored private let session: LiveWorkoutSession
    @ObservationIgnored private weak var transport: (any MirrorTransport)?
    /// True once anything has been heard from the other side on the current transport.
    private(set) var isLinked = false
    /// The watch's latest readings, on the phone.
    private(set) var remoteHeartRate: Double?
    private(set) var remoteActiveEnergy: Double?
    /// The other side finished or discarded; the host ends its own workout the way it does locally.
    @ObservationIgnored var onRemoteFinish: ((Date) -> Void)?
    @ObservationIgnored var onRemoteDiscard: (() -> Void)?
    /// Set while a remote message is being applied, so the session's callbacks do not echo it back.
    @ObservationIgnored private var handlingRemote = false

    init(role: Role, session: LiveWorkoutSession) {
        self.role = role
        self.session = session
        session.onApplied = { [weak self] edit, date in self?.localApplied(edit, at: date) }
        session.onFinish = { [weak self] finished in self?.localFinished(finished) }
        session.onDiscard = { [weak self] in self?.localDiscarded() }
    }

    func attach(_ transport: any MirrorTransport) {
        self.transport = transport
        isLinked = false
    }

    func detach() {
        transport = nil
        isLinked = false
        remoteHeartRate = nil
        remoteActiveEnergy = nil
    }

    var hasTransport: Bool { transport != nil }

    /// Said by both sides when the link comes up; whoever has a workout answers with it.
    func sayHello() {
        send(.hello)
    }

    /// The watch's readings, sent as they change.
    func sendVitals(heartRate: Double?, activeEnergy: Double?) {
        guard role == .watch else { return }
        send(.vitals(heartRate: heartRate, activeEnergy: activeEnergy))
    }

    /// Takes a message from the other side.
    func receive(_ data: Data) {
        guard let message = try? MirrorMessage.decode(data) else { return }
        isLinked = true
        handlingRemote = true
        defer { handlingRemote = false }
        switch message {
        case .hello:
            if let workout = session.workout {
                send(.state(workout))
            }
        case .state(let remote):
            adopt(remote)
        case .edit(let edit, let date):
            guard session.isActive else { return }
            session.apply(edit, at: date)
            if role == .watch, let workout = session.workout {
                send(.state(workout))
            }
        case .vitals(let heartRate, let activeEnergy):
            remoteHeartRate = heartRate
            remoteActiveEnergy = activeEnergy
        case .finish(let date):
            onRemoteFinish?(date)
        case .discard:
            onRemoteDiscard?()
        }
    }

    /// The watch's state wins on the phone unless it is older; the watch takes a phone's state only
    /// when it has no workout of its own (the phone started it).
    private func adopt(_ remote: LiveWorkout) {
        switch role {
        case .phone:
            if let local = session.workout, local.id == remote.id, remote.updatedAt < local.updatedAt {
                return
            }
            session.start(remote)
        case .watch:
            if session.isActive {
                if let workout = session.workout { send(.state(workout)) }
                return
            }
            session.start(remote)
        }
    }

    private func localApplied(_ edit: LiveWorkoutEdit, at date: Date) {
        guard !handlingRemote else { return }
        switch role {
        case .phone:
            send(.edit(edit, at: date))
        case .watch:
            if let workout = session.workout { send(.state(workout)) }
        }
    }

    private func localFinished(_ finished: FinishedWorkout) {
        guard !handlingRemote else { return }
        send(.finish(at: finished.endedAt))
    }

    private func localDiscarded() {
        guard !handlingRemote else { return }
        send(.discard)
    }

    private func send(_ message: MirrorMessage) {
        guard let transport, let data = try? MirrorMessage.encode(message) else { return }
        transport.send(data)
    }
}
