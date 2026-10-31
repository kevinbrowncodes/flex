import Foundation
import Testing
@testable import Flex

/// Two peers over fake transports: the phone and the watch converge on one workout (STORY_009).
@MainActor
struct WorkoutMirrorTests {
    /// A transport that hands bytes to the other peer, at once or when flushed.
    final class FakeTransport: MirrorTransport {
        var other: MirrorPeer?
        var queue: [Data] = []
        var deliversAtOnce = true
        var sentCount = 0

        func send(_ data: Data) {
            sentCount += 1
            if deliversAtOnce {
                other?.receive(data)
            } else {
                queue.append(data)
            }
        }

        func flush() {
            let pending = queue
            queue = []
            for data in pending { other?.receive(data) }
        }
    }

    struct Pair {
        let phoneSession = LiveWorkoutSession(store: nil, resume: false)
        let watchSession = LiveWorkoutSession(store: nil, resume: false)
        let phone: MirrorPeer
        let watch: MirrorPeer
        let phoneTransport = FakeTransport()
        let watchTransport = FakeTransport()

        init() {
            phone = MirrorPeer(role: .phone, session: phoneSession)
            watch = MirrorPeer(role: .watch, session: watchSession)
            phoneTransport.other = watch
            watchTransport.other = phone
            phone.attach(phoneTransport)
            watch.attach(watchTransport)
        }
    }

    private let start = Date(timeIntervalSinceReferenceDate: 814_000_000)

    private func benchWorkout() -> LiveWorkout {
        LiveWorkout(title: "Heavy Push", startedAt: start, exercises: [
            LiveExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", sets: [LiveSet(reps: 8, weight: 185), LiveSet(reps: 6, weight: 205)])
        ], restSeconds: 90)
    }

    @Test("A phone's hello gets the watch's workout, and the watch takes a phone's when it has none")
    func hello() {
        let pair = Pair()
        pair.watchSession.start(benchWorkout())

        pair.phone.sayHello()
        #expect(pair.phoneSession.workout == pair.watchSession.workout)
        #expect(pair.phone.isLinked)
        #expect(pair.watch.isLinked)

        let other = Pair()
        other.phoneSession.start(benchWorkout())
        other.watch.sayHello()
        #expect(other.watchSession.workout == other.phoneSession.workout)
    }

    @Test("An edit on either side reaches the other, and the phone takes the watch's answer")
    func editsFlow() throws {
        let pair = Pair()
        let workout = benchWorkout()
        pair.watchSession.start(workout)
        pair.phone.sayHello()
        let set1 = workout.exercises[0].sets[0].id
        let set2 = workout.exercises[0].sets[1].id

        pair.phoneSession.apply(.setWeight(setID: set1, weight: 195), at: start.addingTimeInterval(60))
        #expect(pair.watchSession.workout?.set(withID: set1)?.weight == 195)
        #expect(pair.phoneSession.workout == pair.watchSession.workout)

        pair.watchSession.apply(.setCompleted(setID: set2, isCompleted: true), at: start.addingTimeInterval(120))
        #expect(pair.phoneSession.workout?.set(withID: set2)?.isCompleted == true)
        #expect(pair.phoneSession.workout?.rest == pair.watchSession.workout?.rest)
        #expect(pair.phoneSession.workout == pair.watchSession.workout)
    }

    @Test("Concurrent edits: two sets both survive; one field ends with the watch's answer on both sides")
    func concurrentEdits() {
        let pair = Pair()
        let workout = benchWorkout()
        pair.watchSession.start(workout)
        pair.phone.sayHello()
        let set1 = workout.exercises[0].sets[0].id
        let set2 = workout.exercises[0].sets[1].id
        pair.phoneTransport.deliversAtOnce = false
        pair.watchTransport.deliversAtOnce = false

        pair.phoneSession.apply(.setWeight(setID: set1, weight: 190), at: start.addingTimeInterval(10))
        pair.watchSession.apply(.setReps(setID: set2, reps: 5), at: start.addingTimeInterval(11))
        pair.phoneTransport.flush()
        pair.watchTransport.flush()
        pair.watchTransport.flush()
        #expect(pair.watchSession.workout?.set(withID: set1)?.weight == 190)
        #expect(pair.watchSession.workout?.set(withID: set2)?.reps == 5)
        #expect(pair.phoneSession.workout == pair.watchSession.workout)

        pair.phoneSession.apply(.setWeight(setID: set1, weight: 100), at: start.addingTimeInterval(20))
        pair.watchSession.apply(.setWeight(setID: set1, weight: 200), at: start.addingTimeInterval(21))
        pair.phoneTransport.flush()
        pair.watchTransport.flush()
        pair.watchTransport.flush()
        #expect(pair.phoneSession.workout?.set(withID: set1)?.weight == pair.watchSession.workout?.set(withID: set1)?.weight)
        #expect(pair.phoneSession.workout == pair.watchSession.workout)
    }

    @Test("A stale state is not adopted; a newer one is")
    func staleState() throws {
        let pair = Pair()
        let workout = benchWorkout()
        pair.phoneSession.start(workout)
        pair.phoneSession.apply(.rename("Mine"), at: start.addingTimeInterval(30)) // the phone's copy is from +30
        var older = workout
        older.apply(.rename("Old"), at: start.addingTimeInterval(10))
        var newer = workout
        newer.apply(.rename("New"), at: start.addingTimeInterval(60))

        pair.phone.receive(try MirrorMessage.encode(.state(older)))
        #expect(pair.phoneSession.workout?.title == "Mine")
        pair.phone.receive(try MirrorMessage.encode(.state(newer)))
        #expect(pair.phoneSession.workout?.title == "New")
    }

    @Test("Finish and discard on either side end both, once")
    func finishAndDiscard() {
        let pair = Pair()
        pair.watchSession.start(benchWorkout())
        pair.phone.sayHello()
        var watchFinishes: [Date] = []
        var phoneFinishes: [Date] = []
        pair.watch.onRemoteFinish = { date in watchFinishes.append(date); _ = pair.watchSession.finish(at: date) }
        pair.phone.onRemoteFinish = { date in phoneFinishes.append(date); _ = pair.phoneSession.finish(at: date) }

        let finished = pair.phoneSession.finish(at: start.addingTimeInterval(2700))
        #expect(finished?.workout.id == pair.watchSession.workout?.id || !pair.watchSession.isActive)
        #expect(watchFinishes == [start.addingTimeInterval(2700)])
        #expect(phoneFinishes.isEmpty) // the watch's finish, caused by ours, does not come back
        #expect(!pair.watchSession.isActive)
        #expect(!pair.phoneSession.isActive)

        let again = Pair()
        again.watchSession.start(benchWorkout())
        again.phone.sayHello()
        var phoneDiscards = 0
        again.phone.onRemoteDiscard = { phoneDiscards += 1; again.phoneSession.discard() }
        again.watchSession.discard()
        #expect(phoneDiscards == 1)
        #expect(!again.phoneSession.isActive)
    }

    @Test("Vitals from the watch show on the phone, and a detach clears them")
    func vitals() {
        let pair = Pair()
        pair.watch.sendVitals(heartRate: 128, activeEnergy: 80)
        #expect(pair.phone.remoteHeartRate == 128)
        #expect(pair.phone.remoteActiveEnergy == 80)
        pair.phone.sendVitals(heartRate: 1, activeEnergy: 1) // only the watch has readings
        #expect(pair.watch.remoteHeartRate == nil)
        pair.phone.detach()
        #expect(pair.phone.remoteHeartRate == nil)
        #expect(!pair.phone.isLinked)
    }

    @Test("Messages round-trip through JSON")
    func codable() throws {
        let workout = benchWorkout()
        let messages: [MirrorMessage] = [
            .hello,
            .state(workout),
            .edit(.setWeight(setID: workout.exercises[0].sets[0].id, weight: 200), at: start),
            .vitals(heartRate: 130, activeEnergy: nil),
            .finish(at: start.addingTimeInterval(10)),
            .discard
        ]
        for message in messages {
            #expect(try MirrorMessage.decode(MirrorMessage.encode(message)) == message)
        }
    }
}
