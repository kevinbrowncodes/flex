import Foundation
import Testing
@testable import FlexWatch

/// Starting, logging and finishing a workout on the wrist (STORY_006).
@MainActor
struct WatchWorkoutTests {
    private var push: SnapshotTemplate { WatchSnapshot.sample.allTemplates[0] }

    @Test("A session started from the sample template has its sets and the rest default")
    func startFromTemplate() throws {
        let session = LiveWorkoutSession(store: nil, resume: false)
        session.start(LiveWorkout(from: push, restSeconds: WatchSnapshot.sample.restSeconds))

        let workout = try #require(session.workout)
        #expect(workout.title == "Heavy Push")
        #expect(workout.restSeconds == 90)
        #expect(workout.exercises.count == 5)
        #expect(workout.exercises[0].sets.map { $0.weight } == [185, 205])
        #expect(workout.exercises[0].currentSetIndex == 0)
        // Typed first: six products inside #expect were too much for the type checker.
        let plannedVolume = Double(185 * 8 + 205 * 6 + 155 * 8 + 175 * 6 + 95 * 8 + 25 * 12)
        #expect(workout.totalVolume == plannedVolume)
    }

    @Test("Done moves through the sets, starts rest, and lands on the last set when all are done")
    func doneFlow() throws {
        let session = LiveWorkoutSession(store: nil, resume: false)
        session.start(LiveWorkout(from: push, restSeconds: 90))
        let bench = try #require(session.workout?.exercises[0])
        #expect(bench.currentSetIndex == 0)
        #expect(!bench.allSetsCompleted)

        session.apply(.setCompleted(setID: bench.sets[0].id, isCompleted: true))
        var current = try #require(session.workout?.exercises[0])
        #expect(current.currentSetIndex == 1)
        #expect(session.workout?.rest?.setID == bench.sets[0].id)
        #expect(!current.allSetsCompleted)

        session.apply(.setCompleted(setID: bench.sets[1].id, isCompleted: true))
        current = try #require(session.workout?.exercises[0])
        #expect(current.currentSetIndex == 1) // every set done: stay on the last one
        #expect(current.allSetsCompleted)
        #expect(session.workout?.completedSetCount == 2)
    }

    @Test("Add Set copies the current set's weight and reps")
    func addSet() throws {
        let session = LiveWorkoutSession(store: nil, resume: false)
        session.start(LiveWorkout(from: push, restSeconds: 0))
        let bench = try #require(session.workout?.exercises[0])

        session.apply(.addSet(exerciseID: bench.id, set: LiveSet(reps: bench.sets[0].reps, weight: bench.sets[0].weight)))

        let sets = try #require(session.workout?.exercises[0].sets)
        #expect(sets.count == 3)
        #expect(sets[2].weight == 185)
        #expect(sets[2].reps == 8)
        #expect(!sets[2].isCompleted)
    }

    @Test("The Crown snaps weight to 2.5 lb and reps to 1, never below zero")
    func crownSteps() {
        #expect(CrownAdjust.snapped(187.3, step: CrownAdjust.weightStep) == 187.5)
        #expect(CrownAdjust.snapped(186.2, step: CrownAdjust.weightStep) == 185)
        #expect(CrownAdjust.snapped(-4, step: CrownAdjust.weightStep) == 0)
        #expect(CrownAdjust.snapped(7.6, step: CrownAdjust.repsStep) == 8)
        #expect(CrownAdjust.snapped(0.4, step: CrownAdjust.repsStep) == 0)
    }

    @Test("Finishing puts one trimmed workout in the outbox and clears the live store")
    func finishToOutbox() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let liveStore = LiveWorkoutStore(url: folder.appendingPathComponent("live-workout.json"))
        let outboxStore = JSONFileStore<[FinishedWorkout]>(url: folder.appendingPathComponent("finished-workouts.json"))
        let session = LiveWorkoutSession(store: liveStore, resume: true)
        let outbox = WatchOutbox(store: outboxStore)
        let start = Date(timeIntervalSinceReferenceDate: 814_000_000)
        session.start(LiveWorkout(from: push, at: start, restSeconds: 90))
        let bench = try #require(session.workout?.exercises[0])
        session.apply(.setCompleted(setID: bench.sets[0].id, isCompleted: true))
        session.apply(.addSet(exerciseID: bench.id, set: LiveSet()))
        #expect(liveStore.load() != nil)

        let finished = try #require(session.finish(at: start.addingTimeInterval(2700)))
        outbox.add(finished)
        outbox.add(finished) // a second add of the same workout changes nothing

        #expect(!session.isActive)
        #expect(liveStore.load() == nil)
        #expect(finished.duration == 2700)
        #expect(finished.workout.exercises[0].sets.count == 2) // the empty added set is gone
        #expect(finished.workout.exercises[0].sets[0].isCompleted)
        #expect(outbox.pending.count == 1)
        #expect(WatchOutbox(store: outboxStore).pending == [finished])

        outbox.remove(id: finished.workout.id)
        #expect(outbox.pending.isEmpty)
        #expect(WatchOutbox(store: outboxStore).pending.isEmpty)
    }
}
