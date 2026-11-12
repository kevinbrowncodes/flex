import Foundation
import SwiftData
import Testing
@testable import Flex

/// Delete Account erases everything Flex holds (STORY_015, BUG_003).
@MainActor
struct AccountEraserTests {
    @Test("Erasing removes every workout, template, folder and custom exercise and re-seeds the library")
    func erasesEverything() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        PreviewData.insertSampleData(into: context)
        context.insert(Exercise(name: "Kevin's Cable Fly", bodyPart: "Chest", isBuiltIn: false))
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Workout>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) > 0)
        #expect(try context.fetchCount(FetchDescriptor<TemplateFolder>()) > 0)

        try AccountEraser.eraseData(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutExercise>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ExerciseSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WorkoutTemplate>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TemplateExercise>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TemplateSet>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TemplateFolder>()) == 0)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.allSatisfy { $0.isBuiltIn })
        #expect(!exercises.contains { $0.name == "Kevin's Cable Fly" })
        #expect(exercises.count == Exercise.loadBundledDefinitions().count)
        #expect(!context.hasChanges)
    }

    @Test("Erasing an empty store succeeds and leaves just the library")
    func erasesEmptyStore() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext

        try AccountEraser.eraseData(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Workout>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == Exercise.loadBundledDefinitions().count)
    }

    @Test("Delete Account ends the workout in progress, resets preferences and signs out")
    func erasesAccount() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        let session = LiveWorkoutSession(store: nil)
        session.start(LiveWorkout(title: "Push", startedAt: Date(), exercises: []))
        let preferences = PreferencesManager()
        preferences.setWorkoutTarget(5)
        preferences.setHasSeenWelcome(true)
        let auth = AuthenticationManager()
        auth.isAuthenticated = true
        auth.userIdentifier = "test-user"

        try AccountEraser.eraseAccount(context: context, session: session, preferences: preferences, auth: auth)

        #expect(session.workout == nil)
        #expect(preferences.workoutTarget == 3)
        #expect(!preferences.hasSeenWelcome)
        #expect(!auth.isAuthenticated)
        #expect(auth.userIdentifier == nil)
    }
}
