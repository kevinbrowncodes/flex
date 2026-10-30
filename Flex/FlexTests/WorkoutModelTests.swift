import Foundation
import SwiftData
import Testing
@testable import Flex

@MainActor
struct WorkoutModelTests {
    @Test("Volume is weight × reps summed across every set")
    func totalVolume() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let bench = Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", isBuiltIn: true)
        context.insert(bench)

        let workout = TestSupport.insertWorkout(
            date: TestSupport.date(2026, 9, 1),
            exercise: bench,
            sets: [(135, 10), (185, 5), (nil, 12), (100, nil)],
            into: context
        )

        // 135×10 + 185×5 + 0 + 100×1
        #expect(workout.totalVolume == 1350 + 925 + 100)
    }

    @Test("Empty sets are detected")
    func emptySets() {
        #expect(ExerciseSet(setNumber: 1).isEmpty)
        #expect(!ExerciseSet(setNumber: 1, reps: 5).isEmpty)
        #expect(!ExerciseSet(setNumber: 1, weight: 45).isEmpty)
        #expect(!ExerciseSet(setNumber: 1, time: "1:00").isEmpty)
        #expect(ExerciseSet(setNumber: 1, time: "").isEmpty)
    }

    @Test("Best set prefers the heaviest weight, then the most reps")
    func bestSet() {
        let workoutExercise = WorkoutExercise(exercise: Exercise(name: "Squat", bodyPart: "Legs"), sets: [
            ExerciseSet(setNumber: 1, reps: 10, weight: 135),
            ExerciseSet(setNumber: 2, reps: 3, weight: 225),
            ExerciseSet(setNumber: 3, reps: 5, weight: 225),
            ExerciseSet(setNumber: 4, reps: 20, weight: nil)
        ])
        #expect(workoutExercise.bestWeight == 225)
        #expect(workoutExercise.bestSet?.reps == 5)
        #expect(workoutExercise.orderedSets.map { $0.setNumber } == [1, 2, 3, 4])
    }

    @Test("The first time an exercise is performed counts as a PR, and only heavier lifts afterwards")
    func personalRecords() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let bench = Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", isBuiltIn: true)
        let squat = Exercise(name: "Squat (Barbell)", bodyPart: "Legs", isBuiltIn: true)
        context.insert(bench)
        context.insert(squat)

        let first = TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 1), exercise: bench, sets: [(185, 5)], into: context)
        let second = TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 8), exercise: bench, sets: [(185, 8)], into: context)
        let third = TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 15), exercise: bench, sets: [(205, 3)], into: context)
        let squats = TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 15, hour: 18), exercise: squat, sets: [(225, 5)], into: context)
        try context.save()

        let all = try context.fetch(FetchDescriptor<Workout>())
        #expect(first.calculatePRCount(comparedTo: all) == 1)   // first ever bench
        #expect(second.calculatePRCount(comparedTo: all) == 0)  // same weight, more reps: not a weight PR
        #expect(third.calculatePRCount(comparedTo: all) == 1)   // heavier
        #expect(squats.calculatePRCount(comparedTo: all) == 1)  // first ever squat
    }

    @Test("Workouts remember the order exercises were added")
    func exerciseOrder() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let a = Exercise(name: "A", bodyPart: "Arms")
        let b = Exercise(name: "B", bodyPart: "Back")
        let c = Exercise(name: "C", bodyPart: "Core")
        [a, b, c].forEach { context.insert($0) }

        let workout = Workout(title: "Ordered", date: Date(), duration: 60, exercises: [
            WorkoutExercise(exercise: c, sets: [ExerciseSet(setNumber: 1, reps: 1)]),
            WorkoutExercise(exercise: a, sets: [ExerciseSet(setNumber: 1, reps: 1)]),
            WorkoutExercise(exercise: b, sets: [ExerciseSet(setNumber: 1, reps: 1)])
        ])
        context.insert(workout)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Workout>()).first)
        #expect(fetched.orderedExercises.map { $0.exercise?.name } == ["C", "A", "B"])
    }

    @Test("Most recent performance ignores unsaved exercises and later workouts")
    func mostRecentPerformance() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let deadlift = Exercise(name: "Deadlift (Barbell)", bodyPart: "Back", isBuiltIn: true)
        context.insert(deadlift)

        TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 1), exercise: deadlift, sets: [(315, 5)], into: context)
        TestSupport.insertWorkout(date: TestSupport.date(2026, 8, 20), exercise: deadlift, sets: [(365, 3)], into: context)
        TestSupport.insertWorkout(date: TestSupport.date(2026, 9, 10), exercise: deadlift, sets: [(405, 1)], into: context)
        try context.save()

        // An in-progress exercise (no workout yet) must never be treated as history.
        let inProgress = WorkoutExercise(exercise: deadlift)

        let previous = deadlift.mostRecentWorkoutExercise(before: TestSupport.date(2026, 9, 1), excluding: inProgress)
        #expect(previous?.bestWeight == 365)

        let latest = deadlift.mostRecentWorkoutExercise(before: .distantFuture, excluding: inProgress)
        #expect(latest?.bestWeight == 405)

        #expect(deadlift.mostRecentWorkoutExercise(before: TestSupport.date(2026, 7, 1)) == nil)
    }

    @Test("Default workout titles follow the time of day")
    func defaultTitles() {
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 7)) == "Morning Workout")
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 13)) == "Afternoon Workout")
        #expect(LiveWorkout.defaultTitle(for: TestSupport.date(2026, 9, 5, hour: 20)) == "Evening Workout")
    }

    @Test("Template sort orders")
    func templateSorting() {
        let older = WorkoutTemplate(name: "Zeta", exercises: [], createdDate: TestSupport.date(2025, 1, 1))
        let newer = WorkoutTemplate(name: "alpha", exercises: [], createdDate: TestSupport.date(2026, 1, 1))
        #expect(TemplateSortOrder.name.sort([older, newer]).map { $0.name } == ["alpha", "Zeta"])
        #expect(TemplateSortOrder.dateCreated.sort([older, newer]).map { $0.name } == ["alpha", "Zeta"])
        #expect(TemplateSortOrder.dateCreated.sort([newer, older]).first?.name == "alpha")
    }
}
