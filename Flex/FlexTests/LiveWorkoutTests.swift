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

    @Test("The current set is the first not done, or the last when all are; volume sums weight × reps")
    func currentSetAndVolume() {
        var (workout, bench, set1, set2) = benchWorkout()
        #expect(workout.exercises[0].currentSetIndex == 0)
        #expect(!workout.exercises[0].allSetsCompleted)
        #expect(workout.totalVolume == 185 * 8 + 205 * 6)

        workout.apply(.setCompleted(setID: set1.id, isCompleted: true))
        #expect(workout.exercises[0].currentSetIndex == 1)
        workout.apply(.setCompleted(setID: set2.id, isCompleted: true))
        #expect(workout.exercises[0].currentSetIndex == 1)
        #expect(workout.exercises[0].allSetsCompleted)

        workout.apply(.addSet(exerciseID: bench.id, set: LiveSet(weight: 100)))
        #expect(workout.exercises[0].currentSetIndex == 2)
        #expect(workout.totalVolume == 185 * 8 + 205 * 6 + 100) // a weight with no reps counts once
        #expect(LiveExercise(name: "Empty", bodyPart: "Arms").currentSetIndex == nil)
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
        #expect(workout.restSeconds == 0)
        #expect(workout.rest == nil)
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
            .setCompleted(setID: set.id, isCompleted: true),
            .setRestSeconds(120),
            .adjustRest(by: -15),
            .skipRest
        ]
        let data = try LiveWorkoutStore.encoder.encode(edits)
        let decoded = try LiveWorkoutStore.decoder.decode([LiveWorkoutEdit].self, from: data)
        #expect(decoded == edits)
    }

    // MARK: - Rest (STORY_003)

    private func restingWorkout() -> (LiveWorkout, LiveSet, LiveSet, Date) {
        var (workout, _, set1, set2) = benchWorkout()
        workout.restSeconds = 90
        return (workout, set1, set2, workout.startedAt.addingTimeInterval(600))
    }

    @Test("Ticking a set starts rest for the default; ticking another restarts it")
    func completingStartsRest() {
        var (workout, set1, set2, t) = restingWorkout()
        #expect(workout.restRemaining(at: t) == nil)

        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)
        #expect(workout.rest?.setID == set1.id)
        #expect(workout.rest?.startedAt == t)
        #expect(workout.rest?.endsAt == t.addingTimeInterval(90))
        #expect(workout.restRemaining(at: t) == 90)
        #expect(workout.restRemaining(at: t.addingTimeInterval(30)) == 60)
        #expect(workout.restRemaining(at: t.addingTimeInterval(90)) == nil)

        workout.apply(.setCompleted(setID: set2.id, isCompleted: true), at: t.addingTimeInterval(20))
        #expect(workout.rest?.setID == set2.id)
        #expect(workout.rest?.endsAt == t.addingTimeInterval(110))
    }

    @Test("Unticking the set that started a rest cancels it; unticking another leaves it")
    func uncompletingCancelsRest() {
        var (workout, set1, set2, t) = restingWorkout()
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)
        workout.apply(.setCompleted(setID: set2.id, isCompleted: true), at: t.addingTimeInterval(20))

        workout.apply(.setCompleted(setID: set1.id, isCompleted: false), at: t.addingTimeInterval(25))
        #expect(workout.rest?.setID == set2.id)

        workout.apply(.setCompleted(setID: set2.id, isCompleted: false), at: t.addingTimeInterval(30))
        #expect(workout.rest == nil)
    }

    @Test("Rest off starts nothing, and the default can change mid-workout")
    func restDefault() {
        var (workout, _, set1, _) = benchWorkout()
        let t = workout.startedAt
        #expect(workout.restSeconds == 0)
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)
        #expect(workout.rest == nil)

        workout.apply(.setRestSeconds(120), at: t)
        workout.apply(.setCompleted(setID: set1.id, isCompleted: false), at: t)
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)
        #expect(workout.rest?.endsAt == t.addingTimeInterval(120))

        workout.apply(.setRestSeconds(-5), at: t)
        #expect(workout.restSeconds == 0)
        #expect(LiveWorkout(startedAt: t, restSeconds: -1).restSeconds == 0)
    }

    @Test("Nudging moves the end, never into the past; skipping clears it")
    func adjustAndSkip() {
        var (workout, set1, _, t) = restingWorkout()
        let before = workout.updatedAt
        workout.apply(.adjustRest(by: 15), at: t)
        workout.apply(.skipRest, at: t)
        #expect(workout.updatedAt == before) // nothing running: nothing happened

        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)
        workout.apply(.adjustRest(by: 15), at: t.addingTimeInterval(10))
        #expect(workout.rest?.endsAt == t.addingTimeInterval(105))
        workout.apply(.adjustRest(by: -1000), at: t.addingTimeInterval(30))
        #expect(workout.rest?.endsAt == t.addingTimeInterval(30))
        #expect(workout.restRemaining(at: t.addingTimeInterval(30)) == nil)
        workout.apply(.adjustRest(by: 60), at: t.addingTimeInterval(31)) // already over: stays over
        #expect(workout.restRemaining(at: t.addingTimeInterval(31)) == nil)

        workout.apply(.setCompleted(setID: set1.id, isCompleted: false), at: t.addingTimeInterval(40))
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t.addingTimeInterval(40))
        workout.apply(.skipRest, at: t.addingTimeInterval(41))
        #expect(workout.rest == nil)
    }

    @Test("Finishing drops the rest, and the running rest survives a trip through JSON")
    func restPersistsAndFinishes() throws {
        var (workout, set1, _, t) = restingWorkout()
        workout.apply(.setCompleted(setID: set1.id, isCompleted: true), at: t)

        let data = try LiveWorkoutStore.encoder.encode(workout)
        let decoded = try LiveWorkoutStore.decoder.decode(LiveWorkout.self, from: data)
        #expect(decoded == workout)
        #expect(decoded.restRemaining(at: t.addingTimeInterval(45)) == 45)

        #expect(workout.finished(at: t.addingTimeInterval(60)).workout.rest == nil)
    }

    @Test("The rest default offers Off to five minutes and reads a stored value or 90")
    func restTimerDefaults() {
        #expect(RestTimer.defaultSeconds == 90)
        #expect(RestTimer.options.first == 0)
        #expect(RestTimer.options.last == 300)
        #expect(RestTimer.options == RestTimer.options.sorted())
        #expect(RestTimer.label(0) == "Off")
        #expect(RestTimer.label(45) == "0:45")
        #expect(RestTimer.label(90) == "1:30")
        #expect(RestTimer.label(300) == "5:00")
        #expect(RestTimer.seconds(stored: nil) == 90)
        #expect(RestTimer.seconds(stored: NSNumber(value: 0)) == 0)   // Off is a choice, not "unset"
        #expect(RestTimer.seconds(stored: NSNumber(value: 120)) == 120)
        #expect(RestTimer.seconds(stored: NSNumber(value: -3)) == 0)
        #expect(RestTimer.seconds(stored: "junk") == 90)
    }
}
