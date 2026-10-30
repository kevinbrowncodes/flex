import Foundation
import SwiftData
import Testing
@testable import Flex

@MainActor
struct ExerciseLibraryTests {
    private func bundled() -> [Exercise] {
        [
            Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, isBuiltIn: true),
            Exercise(name: "Squat (Barbell)", bodyPart: "Legs", barType: .olympicBarbell, isBuiltIn: true),
            Exercise(name: "Pull Up", bodyPart: "Back", isBuiltIn: true)
        ]
    }

    @Test("The bundled Exercises.json decodes and has no duplicate names")
    func bundledLibraryIsClean() {
        let definitions = Exercise.loadBundledDefinitions()
        #expect(definitions.count > 200)
        let names = definitions.map { $0.name }
        #expect(Set(names).count == names.count)
        #expect(definitions.allSatisfy { !$0.name.isEmpty && !$0.bodyPart.isEmpty && !$0.category.isEmpty })
        // Every barbell exercise should declare a bar so the plate calculator works.
        let barbellWithoutBar = definitions.filter { $0.name.contains("(Barbell)") && $0.barType == nil }
        #expect(barbellWithoutBar.isEmpty)
    }

    @Test("First launch seeds the whole library")
    func seedsOnFirstLaunch() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext

        let result = try ExerciseLibrary.synchronize(context: context, bundled: bundled())

        #expect(result == ExerciseLibrary.SyncResult(inserted: 3, duplicatesMerged: 0))
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 3)

        // A second launch changes nothing.
        let again = try ExerciseLibrary.synchronize(context: context, bundled: bundled())
        #expect(again == ExerciseLibrary.SyncResult())
    }

    @Test("New bundled exercises are added, custom and soft-deleted ones are left alone")
    func addsNewBundledExercises() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        context.insert(Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", isBuiltIn: true))
        context.insert(Exercise(name: "Pull Up", bodyPart: "Back", isBuiltIn: true, isArchived: true))
        context.insert(Exercise(name: "My Cable Fly", bodyPart: "Chest"))
        try context.save()

        let result = try ExerciseLibrary.synchronize(context: context, bundled: bundled())

        #expect(result.inserted == 1) // Squat
        #expect(result.duplicatesMerged == 0)
        let names = Set(try context.fetch(FetchDescriptor<Exercise>()).map { $0.name })
        #expect(names == ["Bench Press (Barbell)", "Pull Up", "My Cable Fly", "Squat (Barbell)"])
        let pullUp = try #require(try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Pull Up" })
        #expect(pullUp.isArchived, "a deleted built-in must not be resurrected")
    }

    @Test("CloudKit duplicates are merged and history is re-pointed at the survivor")
    func mergesDuplicatesKeepingHistory() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext

        let original = Exercise(name: "Squat (Barbell)", bodyPart: "Legs", barType: .olympicBarbell, isBuiltIn: true)
        let duplicate = Exercise(name: "Squat (Barbell)", bodyPart: "Legs", isBuiltIn: true)
        let custom = Exercise(name: "Squat (Barbell)", bodyPart: "Legs", isBuiltIn: false)
        context.insert(original)
        context.insert(duplicate)
        context.insert(custom)

        // History attached to the copies that will be removed.
        let workout = TestSupport.insertWorkout(date: Date(), exercise: duplicate, sets: [(225, 5)], into: context)
        let template = WorkoutTemplate(name: "Legs", exercises: [custom])
        context.insert(template)
        try context.save()

        let result = try ExerciseLibrary.synchronize(context: context, bundled: bundled())

        #expect(result.duplicatesMerged == 2)
        let squats = try context.fetch(FetchDescriptor<Exercise>()).filter { $0.name == "Squat (Barbell)" }
        #expect(squats.count == 1)
        let survivor = try #require(squats.first)
        #expect(survivor.isBuiltIn)
        #expect(survivor.barType == .olympicBarbell)
        #expect(workout.orderedExercises.first?.exercise === survivor, "workout history must follow the surviving exercise")
        #expect(template.exercises.first === survivor, "templates must follow the surviving exercise")
    }

    @Test("The most-used copy wins when both are custom")
    func prefersCopyWithHistory() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let unused = Exercise(name: "Cable Fly", bodyPart: "Chest")
        let used = Exercise(name: "Cable Fly", bodyPart: "Chest")
        context.insert(unused)
        context.insert(used)
        TestSupport.insertWorkout(date: Date(), exercise: used, sets: [(30, 12)], into: context)
        try context.save()

        #expect(ExerciseLibrary.preferredKeeper(among: [unused, used]) === used)

        let removed = try ExerciseLibrary.mergeDuplicates(context: context)
        #expect(removed == 1)
        let remaining = try context.fetch(FetchDescriptor<Exercise>())
        #expect(remaining.count == 1)
        #expect(remaining.first === used)
    }

    @Test("Names are compared after trimming whitespace")
    func normalizesNames() {
        #expect(ExerciseLibrary.normalized("  Bench Press  ") == "Bench Press")
    }
}
