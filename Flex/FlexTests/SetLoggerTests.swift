import Foundation
import Testing
@testable import Flex

/// What Siri's "log a set" does to a live workout, as pure edits plus the sentence (STORY_010).
@MainActor
struct SetLoggerTests {
    private let now = TestSupport.date(2026, 10, 30, hour: 19)
    private let bench = CatalogExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell)

    private func runningWorkout() -> LiveWorkout {
        LiveWorkout(title: "Heavy Push", startedAt: now.addingTimeInterval(-600), exercises: [
            LiveExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, sets: [
                LiveSet(reps: 8, weight: 185, isCompleted: true),
                LiveSet(reps: 6, weight: 205)
            ])
        ], restSeconds: 90)
    }

    @Test("A running workout with the exercise: the first set not done is filled and completed, and rest starts")
    func fillsTheNextSet() {
        let workout = runningWorkout()
        let result = SetLogger.log(exercise: bench, weight: 135, reps: 8, into: workout, restSeconds: 90, at: now)

        #expect(!result.startedWorkout)
        #expect(result.sentence == "Logged 135 lb × 8 on Bench Press (Barbell).")
        let sets = result.workout.exercises[0].sets
        #expect(sets.count == 2)
        #expect(sets[1].weight == 135)
        #expect(sets[1].reps == 8)
        #expect(sets[1].isCompleted)
        #expect(result.workout.rest?.setID == sets[1].id)
        #expect(result.edits.count == 3)

        // The edits replay onto the original to the same place.
        var replayed = workout
        for edit in result.edits { replayed.apply(edit, at: now) }
        #expect(replayed == result.workout)
    }

    @Test("Every set done: a new set is added and logged")
    func addsASetWhenAllAreDone() {
        var workout = runningWorkout()
        workout.apply(.setCompleted(setID: workout.exercises[0].sets[1].id, isCompleted: true), at: now.addingTimeInterval(-60))
        let result = SetLogger.log(exercise: bench, weight: 225, reps: 3, into: workout, restSeconds: 90, at: now)

        let sets = result.workout.exercises[0].sets
        #expect(sets.count == 3)
        #expect(sets[2].weight == 225)
        #expect(sets[2].reps == 3)
        #expect(sets[2].isCompleted)
        #expect(result.edits.count == 4)
        #expect(result.sentence == "Logged 225 lb × 3 on Bench Press (Barbell).")
    }

    @Test("An exercise the workout lacks is added with the logged set")
    func addsTheExercise() {
        let squat = CatalogExercise(name: "Squat (Barbell)", bodyPart: "Legs", barType: .olympicBarbell)
        let result = SetLogger.log(exercise: squat, weight: 315, reps: 5, into: runningWorkout(), restSeconds: 90, at: now)

        #expect(result.workout.exercises.map { $0.name } == ["Bench Press (Barbell)", "Squat (Barbell)"])
        let added = result.workout.exercises[1]
        #expect(added.barType == .olympicBarbell)
        #expect(added.sets.count == 1)
        #expect(added.sets[0].weight == 315)
        #expect(added.sets[0].isCompleted)
        #expect(result.edits.count == 4)
        #expect(result.sentence == "Logged 315 lb × 5 on Squat (Barbell).")
    }

    @Test("No workout running: one is started by time of day and the set logged in it")
    func startsAWorkout() {
        let result = SetLogger.log(exercise: bench, weight: 135, reps: 8, into: nil, restSeconds: 120, at: now)

        #expect(result.startedWorkout)
        #expect(result.edits.isEmpty) // the workout itself is what to start with
        #expect(result.workout.title == "Evening Workout")
        #expect(result.workout.startedAt == now)
        #expect(result.workout.restSeconds == 120)
        #expect(result.workout.exercises.count == 1)
        #expect(result.workout.exercises[0].sets[0].weight == 135)
        #expect(result.workout.exercises[0].sets[0].isCompleted)
        #expect(result.workout.rest?.endsAt == now.addingTimeInterval(120))
        #expect(result.sentence == "Started Evening Workout and logged 135 lb × 8 on Bench Press (Barbell).")
    }

    @Test("Bodyweight reads as reps, and negatives are clamped")
    func bodyweightAndClamping() {
        let dips = CatalogExercise(name: "Dips", bodyPart: "Chest")
        let result = SetLogger.log(exercise: dips, weight: 0, reps: 12, into: runningWorkout(), restSeconds: 90, at: now)
        #expect(result.sentence == "Logged 12 reps on Dips.")

        let odd = SetLogger.log(exercise: dips, weight: -5, reps: -1, into: runningWorkout(), restSeconds: 90, at: now)
        let set = odd.workout.exercises[1].sets[0]
        #expect(set.weight == 0)
        #expect(set.reps == 0)
    }

    @Test("The catalog ranks what Siri may mean: the live workout's exercises first, each name once")
    func ranking() {
        let all = [
            CatalogExercise(name: "Incline Bench Press (Barbell)", bodyPart: "Chest"),
            CatalogExercise(name: "Bench Press (Dumbbell)", bodyPart: "Chest"),
            CatalogExercise(name: "Bench Press (Barbell)", bodyPart: "Chest"),
            CatalogExercise(name: "Bench Press (Barbell)", bodyPart: "Chest"),
            CatalogExercise(name: "Squat (Barbell)", bodyPart: "Legs")
        ]
        let ranked = CatalogRanking.rank(all, matching: "bench press", inWorkout: ["Bench Press (Dumbbell)"])
        #expect(ranked.map { $0.name } == ["Bench Press (Dumbbell)", "Bench Press (Barbell)", "Incline Bench Press (Barbell)"])
        #expect(CatalogRanking.rank(all, matching: "", inWorkout: []).count == 4)
        #expect(CatalogRanking.rank(all, matching: "deadlift", inWorkout: []).isEmpty)
    }
}
