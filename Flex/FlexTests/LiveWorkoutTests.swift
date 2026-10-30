import Foundation
import Testing
@testable import Flex

/// The workout in progress as a value: edits, finishing, and the JSON it is kept as (STORY_002).
@MainActor
struct LiveWorkoutTests {
    private func benchWorkout() -> (LiveWorkout, LiveExercise, LiveSet, LiveSet) {
        let set1 = LiveSet(reps: 8, weight: 185)
        let set2 = LiveSet(reps: 6, weight: 205)
        let bench = LiveExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, sets: [set1, set2],
                                 previousSets: [LiveSet(reps: 8, weight: 180), LiveSet(reps: 6, weight: 200)])
        let workout = LiveWorkout(title: "Heavy Push", startedAt: TestSupport.date(2026, 10, 30, hour: 18), templateName: "Heavy Push", exercises: [bench])
        return (workout, bench, set1, set2)
    }

    @Test("Set edits change the one set they name and stamp the workout")
    func setEdits() {
        var (workout, _, set1, set2) = benchWorkout()
        let later = TestSupport.date(2026, 10, 30, hour: 19)

        workout.apply(.setWeight(setID: set1.id, weight: 205), at: later)
        workout.apply(.setReps(setID: set1.id, reps: 10), at: later)
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: later)
        workout.apply(.setTime(setID: set2.id, time: "1:30"), at: later)

        let first = workout.set(withID: set1.id)!
        #expect(first.weight == 205)
        #expect(first.reps == 10)
        #expect(first.isCompleted)
        #expect(workout.set(withID: set2.id)?.time == "1:30")
        #expect(workout.set(withID: set2.id)?.weight == 205) // untouched
        #expect(workout.updatedAt == later)

        workout.apply(.setTime(setID: set2.id, time: ""))
        #expect(workout.set(withID: set2.id)?.time == nil)
        workout.apply(.setWeight(setID: set2.id, weight: nil))
        #expect(workout.set(withID: set2.id)?.weight == nil)
    }

    @Test("Adding and deleting sets renumbers by position")
    func addAndDeleteSets() {
        var (workout, bench, set1, set2) = benchWorkout()
        let set3 = LiveSet(reps: 4, weight: 225)

        workout.apply(.addSet(exerciseID: bench.id, set: set3))
        #expect(workout.exercise(withID: bench.id)?.sets.map { $0.id } == [set1.id, set2.id, set3.id])

        workout.apply(.deleteSet(exerciseID: bench.id, setID: set1.id))
        let remaining = workout.exercise(withID: bench.id)!.sets
        #expect(remaining.map { $0.id } == [set2.id, set3.id])
        #expect(remaining.count == 2) // set numbers are positions: 1 and 2 again
    }

    @Test("Exercises are added, removed and renamed")
    func exercises() {
        var (workout, bench, _, _) = benchWorkout()
        let squat = LiveExercise(name: "Squat (Barbell)", bodyPart: "Legs", sets: [LiveSet()])

        workout.apply(.addExercise(squat))
        #expect(workout.exercises.map { $0.name } == ["Bench Press (Barbell)", "Squat (Barbell)"])

        workout.apply(.removeExercise(exerciseID: bench.id))
        #expect(workout.exercises.map { $0.name } == ["Squat (Barbell)"])

        workout.apply(.rename("  Leg Day  "))
        #expect(workout.title == "Leg Day")
        workout.apply(.rename("   "))
        #expect(workout.title == "Leg Day") // blank names are ignored
    }

    @Test("A repeated add and an edit naming an unknown id change nothing")
    func idempotentAndUnknown() {
        let (original, bench, set1, _) = benchWorkout()
        var workout = original
        let before = workout.updatedAt

        workout.apply(.addExercise(bench))
        workout.apply(.addSet(exerciseID: bench.id, set: set1))
        workout.apply(.setWeight(setID: UUID(), weight: 999))
        workout.apply(.deleteSet(exerciseID: bench.id, setID: UUID()))
        workout.apply(.removeExercise(exerciseID: UUID()))
        workout.apply(.addSet(exerciseID: UUID(), set: LiveSet(reps: 1)))

        #expect(workout == original)
        #expect(workout.updatedAt == before)
    }

    @Test("Finishing drops empty sets and exercises with nothing logged, and keeps completed flags")
    func finishing() {
        var (workout, bench, set1, _) = benchWorkout()
        let empty = LiveExercise(name: "Curl (Dumbbell)", bodyPart: "Arms", sets: [LiveSet(), LiveSet()])
        workout.apply(.addExercise(empty))
        workout.apply(.addSet(exerciseID: bench.id, set: LiveSet()))
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true))
        #expect(workout.loggedSetCount == 2)
        #expect(workout.completedSetCount == 1)
        #expect(workout.hasEmptySets)

        let end = workout.startedAt.addingTimeInterval(50 * 60)
        let finished = workout.finished(at: end)

        #expect(finished.duration == 3000)
        #expect(finished.workout.id == workout.id)
        #expect(finished.workout.exercises.map { $0.name } == ["Bench Press (Barbell)"])
        #expect(finished.workout.exercises[0].sets.count == 2)
        #expect(finished.workout.exercises[0].sets[0].isCompleted)
        #expect(!finished.workout.exercises[0].sets[1].isCompleted)
        #expect(!finished.workout.hasEmptySets)
    }

    @Test("Default workout titles follow the time of day, and a new workout takes one")
    func defaultTitles() {
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 4)) == "Morning Workout")
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 12)) == "Afternoon Workout")
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 17)) == "Evening Workout")
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 1)) == "Evening Workout")
        #expect(LiveWorkout(startedAt: TestSupport.date(2026, 9, 5, hour: 9)).title == "Morning Workout")
    }

    @Test("The store round-trips a workout through JSON and clears it")
    func storeRoundTrip() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LiveWorkoutStore(url: folder.appendingPathComponent("live-workout.json"))
        let (workout, _, _, _) = benchWorkout()

        #expect(store.load() == nil)
        try store.save(workout)
        #expect(store.load() == workout)

        store.clear()
        #expect(store.load() == nil)
    }

    @Test("A file that will not decode counts as no workout and is removed")
    func storeIgnoresGarbage() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        try Data("not json".utf8).write(to: url)
        let store = LiveWorkoutStore(url: url)

        #expect(store.load() == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Older JSON without optional keys still decodes")
    func decodesSparseJSON() throws {
        let json = """
        {"id":"8F4C2D7E-1B2A-4C3D-9E8F-000000000001","startedAt":1793390400,
         "exercises":[{"id":"8F4C2D7E-1B2A-4C3D-9E8F-000000000002","name":"Pull Up",
                       "sets":[{"id":"8F4C2D7E-1B2A-4C3D-9E8F-000000000003","reps":10}]}]}
        """
        let workout = try LiveWorkoutStore.decoder.decode(LiveWorkout.self, from: Data(json.utf8))

        #expect(workout.title == LiveWorkout.defaultTitle(for: workout.startedAt))
        #expect(workout.templateName == nil)
        #expect(workout.updatedAt == workout.startedAt)
        #expect(workout.exercises.count == 1)
        #expect(workout.exercises[0].category == "Strength")
        #expect(workout.exercises[0].previousSets.isEmpty)
        #expect(workout.exercises[0].sets[0].reps == 10)
        #expect(!workout.exercises[0].sets[0].isCompleted)
    }

    @Test("Edits themselves round-trip through JSON")
    func editsAreCodable() throws {
        let set = LiveSet(reps: 5, weight: 100)
        let edits: [LiveWorkoutEdit] = [
            .rename("Push"),
            .addExercise(LiveExercise(name: "Dip", bodyPart: "Chest")),
            .removeExercise(exerciseID: UUID()),
            .addSet(exerciseID: UUID(), set: set),
            .deleteSet(exerciseID: UUID(), setID: set.id),
            .setWeight(setID: set.id, weight: nil),
            .setReps(setID: set.id, reps: 3),
            .setTime(setID: set.id, time: "0:45"),
            .setCompleted(setID: set.id, isCompleted: true)
        ]
        let data = try LiveWorkoutStore.encoder.encode(edits)
        let decoded = try LiveWorkoutStore.decoder.decode([LiveWorkoutEdit].self, from: data)
        #expect(decoded == edits)
    }
}
