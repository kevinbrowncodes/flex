import Foundation
import SwiftData
import Testing
@testable import Flex

/// Where the live workout meets SwiftData: starting from a template and saving when finished (STORY_002).
@MainActor
struct LiveWorkoutBridgeTests {
    @Test("Starting from a template copies its sets and each exercise's last performance")
    func startFromTemplate() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let bench = Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, isBuiltIn: true)
        let fly = Exercise(name: "Chest Fly (Cable)", bodyPart: "Chest", isBuiltIn: true)
        context.insert(bench)
        context.insert(fly)
        TestSupport.insertWorkout(date: TestSupport.date(2026, 10, 1), exercise: bench, sets: [(175, 8), (195, 6)], into: context)
        TestSupport.insertWorkout(date: TestSupport.date(2026, 10, 8), exercise: bench, sets: [(180, 8), (200, 6)], into: context)
        let template = WorkoutTemplate(name: "Heavy Push", templateExercises: [
            TemplateExercise(exercise: bench, sets: [TemplateSet(setNumber: 1, reps: 8, weight: 185), TemplateSet(setNumber: 2, reps: 6, weight: 205)], order: 0),
            TemplateExercise(exercise: fly, sets: [], order: 1)
        ])
        context.insert(template)
        try context.save()

        let start = TestSupport.date(2026, 10, 30, hour: 18)
        let live = LiveWorkoutBridge.start(from: template, at: start)

        #expect(live.title == "Heavy Push")
        #expect(live.templateName == "Heavy Push")
        #expect(live.startedAt == start)
        #expect(live.exercises.map { $0.name } == ["Bench Press (Barbell)", "Chest Fly (Cable)"])
        #expect(live.exercises[0].barType == .olympicBarbell)
        #expect(live.exercises[0].sets.map { $0.weight } == [185, 205])
        #expect(live.exercises[0].sets.map { $0.reps } == [8, 6])
        #expect(live.exercises[0].previousSets.map { $0.weight } == [180, 200]) // the most recent, not the heaviest
        #expect(live.exercises[1].sets.count == 1)                              // a template with no sets starts with one empty set
        #expect(live.exercises[1].sets[0].isEmpty)
        #expect(live.exercises[1].previousSets.isEmpty)

        let empty = LiveWorkoutBridge.start(from: nil, at: start)
        #expect(empty.exercises.isEmpty)
        #expect(empty.title == "Evening Workout")
    }

    @Test("Saving makes one Workout with the live id, exercises in order, sets renumbered")
    func save() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let bench = Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", isBuiltIn: true)
        let squat = Exercise(name: "Squat (Barbell)", bodyPart: "Legs", isBuiltIn: true)
        context.insert(bench)
        context.insert(squat)
        try context.save()

        var live = LiveWorkout(title: "Push", startedAt: TestSupport.date(2026, 10, 30, hour: 18), exercises: [
            LiveExercise(name: "Squat (Barbell)", bodyPart: "Legs", sets: [LiveSet(reps: 5, weight: 225, isCompleted: true), LiveSet(), LiveSet(reps: 3, weight: 245)]),
            LiveExercise(name: " Bench Press (Barbell) ", bodyPart: "Chest", sets: [LiveSet(reps: 8, weight: 185)])
        ])
        live.apply(.rename("Lower"))
        let finished = live.finished(at: live.startedAt.addingTimeInterval(2700))

        let saved = try LiveWorkoutBridge.save(finished, into: context)

        #expect(saved.id == live.id)
        #expect(saved.title == "Lower")
        #expect(saved.date == live.startedAt)
        #expect(saved.duration == 2700)
        let exercises = saved.orderedExercises
        #expect(exercises.map { $0.exercise?.name } == ["Squat (Barbell)", "Bench Press (Barbell)"])
        #expect(exercises[0].exercise === squat)
        #expect(exercises[1].exercise === bench) // matched by name, surrounding spaces ignored
        #expect(exercises[0].orderedSets.map { $0.setNumber } == [1, 2])   // the empty set is gone, numbers closed up
        #expect(exercises[0].orderedSets.map { $0.weight } == [225, 245])
        #expect(exercises[0].orderedSets.map { $0.isCompleted } == [true, false])
        #expect(try context.fetch(FetchDescriptor<Workout>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == 2)   // nothing new created
    }

    @Test("Saving the same finished workout twice saves it once")
    func saveIsIdempotent() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        context.insert(Exercise(name: "Pull Up", bodyPart: "Back", isBuiltIn: true))
        let live = LiveWorkout(title: "Pull", startedAt: TestSupport.date(2026, 10, 30), exercises: [
            LiveExercise(name: "Pull Up", bodyPart: "Back", sets: [LiveSet(reps: 10)])
        ])
        let finished = live.finished(at: live.startedAt.addingTimeInterval(600))

        let first = try LiveWorkoutBridge.save(finished, into: context)
        let second = try LiveWorkoutBridge.save(finished, into: context)

        #expect(first === second)
        #expect(try context.fetch(FetchDescriptor<Workout>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<WorkoutExercise>()).count == 1)
    }

    @Test("An unknown exercise becomes a custom one; an archived one is matched, not duplicated")
    func exerciseResolution() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let archived = Exercise(name: "Zercher Squat", bodyPart: "Legs", isArchived: true)
        context.insert(archived)
        try context.save()
        let live = LiveWorkout(title: "Odd Lifts", startedAt: TestSupport.date(2026, 10, 30), exercises: [
            LiveExercise(name: "Zercher Squat", bodyPart: "Legs", sets: [LiveSet(reps: 5, weight: 135)]),
            LiveExercise(name: "Jefferson Deadlift", bodyPart: "Legs", category: "Strength", barType: .olympicBarbell, sets: [LiveSet(reps: 5, weight: 185)])
        ])

        let saved = try LiveWorkoutBridge.save(live.finished(at: live.startedAt.addingTimeInterval(900)), into: context)

        let exercises = saved.orderedExercises
        #expect(exercises[0].exercise === archived)
        let created = try #require(exercises[1].exercise)
        #expect(created.name == "Jefferson Deadlift")
        #expect(created.bodyPart == "Legs")
        #expect(created.barType == .olympicBarbell)
        #expect(!created.isBuiltIn)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == 2)
    }

    @Test("The session persists every edit and clears the store when finished or discarded")
    func sessionPersists() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        context.insert(Exercise(name: "Dip", bodyPart: "Chest", isBuiltIn: true))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        let store = LiveWorkoutStore(url: url)
        defer { store.clear() }

        let session = LiveWorkoutSession(store: store, resume: true)
        #expect(!session.isActive)
        let dip = LiveExercise(name: "Dip", bodyPart: "Chest", sets: [LiveSet()])
        session.start(LiveWorkout(title: "Push", startedAt: TestSupport.date(2026, 10, 30), exercises: [dip]))
        session.apply(.setReps(setID: dip.sets[0].id, reps: 12))

        let resumed = LiveWorkoutSession(store: store, resume: true)
        #expect(resumed.workout == session.workout)
        #expect(resumed.workout?.set(withID: dip.sets[0].id)?.reps == 12)

        let saved = try #require(try resumed.finish(into: context, at: TestSupport.date(2026, 10, 30, hour: 13)))
        #expect(saved.orderedExercises.first?.orderedSets.first?.reps == 12)
        #expect(!resumed.isActive)
        #expect(store.load() == nil)

        let cleared = LiveWorkoutSession(store: store, resume: false)
        #expect(!cleared.isActive)
        session.start(LiveWorkout(startedAt: TestSupport.date(2026, 10, 30)))
        #expect(store.load() != nil)
        session.discard()
        #expect(store.load() == nil)
    }
}
