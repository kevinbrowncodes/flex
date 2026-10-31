import Foundation
import SwiftData
import Testing
@testable import Flex

/// The phone's catalog for Siri: the library without archived exercises, the live workout first (STORY_010).
@MainActor
struct ExerciseCatalogTests {
    @Test("Archived exercises are left out; the live workout's come first; both bench presses match")
    func catalog() async throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        context.insert(Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, isBuiltIn: true))
        context.insert(Exercise(name: "Bench Press (Dumbbell)", bodyPart: "Chest", isBuiltIn: true))
        context.insert(Exercise(name: "Old Bench Press (Smith)", bodyPart: "Chest", isArchived: true))
        context.insert(Exercise(name: "Squat (Barbell)", bodyPart: "Legs", barType: .olympicBarbell, isBuiltIn: true))
        try context.save()
        let session = LiveWorkoutSession(store: nil, resume: false)
        let preferences = PreferencesManager()
        let catalog = PhoneWorkoutCatalog(container: container, session: session, preferences: preferences)

        #expect(catalog.all().map { $0.name } == ["Bench Press (Barbell)", "Bench Press (Dumbbell)", "Squat (Barbell)"])
        #expect(await catalog.exercises(matching: "bench press").map { $0.name } == ["Bench Press (Barbell)", "Bench Press (Dumbbell)"])
        #expect(await catalog.exercise(id: "Bench Press (Barbell)")?.barType == .olympicBarbell)
        #expect(await catalog.exercise(id: "Old Bench Press (Smith)") == nil)
        #expect(await catalog.suggestedExercises().count == 3)
        #expect(await catalog.restSeconds == preferences.restSeconds)

        session.start(LiveWorkout(startedAt: Date(), exercises: [
            LiveExercise(name: "Bench Press (Dumbbell)", bodyPart: "Chest", sets: [LiveSet()])
        ]))
        #expect(await catalog.exercises(matching: "bench").map { $0.name } == ["Bench Press (Dumbbell)", "Bench Press (Barbell)"])
        #expect(await catalog.suggestedExercises().map { $0.name } == ["Bench Press (Dumbbell)"])
    }
}
