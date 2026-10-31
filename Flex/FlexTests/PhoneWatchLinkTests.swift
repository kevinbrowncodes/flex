import Foundation
import SwiftData
import Testing
@testable import Flex

/// The phone saving what the watch finished (STORY_007). No WCSession: the link is never activated.
@MainActor
struct PhoneWatchLinkTests {
    private func makeLink(container: ModelContainer) -> PhoneWatchLink {
        PhoneWatchLink(
            makeSnapshot: {
                try WatchSnapshotBuilder.make(context: container.mainContext, weeklyTarget: 3, restSeconds: 90, userName: nil, sortOrder: .name)
            },
            saveFinished: { try LiveWorkoutBridge.save($0, into: container.mainContext) }
        )
    }

    private func finishedWorkout(start: Date) -> FinishedWorkout {
        let bench = LiveExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, sets: [
            LiveSet(reps: 8, weight: 185, isCompleted: true),
            LiveSet(reps: 6, weight: 205, isCompleted: true),
            LiveSet()
        ])
        let live = LiveWorkout(title: "Heavy Push", startedAt: start, templateName: "Heavy Push", exercises: [bench], restSeconds: 90)
        return live.finished(at: start.addingTimeInterval(2700))
    }

    private func userInfo(for finished: FinishedWorkout) throws -> [String: Any] {
        [
            WatchSnapshot.finishedKey: try FlexJSON.encoder.encode(finished),
            WatchSnapshot.finishedIDKey: finished.workout.id.uuidString
        ]
    }

    @Test("A finished workout from the watch is saved once, with its sets, and counts toward the week")
    func savesOnce() throws {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        context.insert(Exercise(name: "Bench Press (Barbell)", bodyPart: "Chest", barType: .olympicBarbell, isBuiltIn: true))
        try context.save()
        let link = makeLink(container: container)
        let now = Date()
        let finished = finishedWorkout(start: now.addingTimeInterval(-3600))
        let before = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: nil, now: now, sortOrder: .name)

        let decoded = try #require(PhoneWatchLink.finishedWorkout(in: try userInfo(for: finished)))
        #expect(decoded == finished)
        let saved = try #require(link.receive(decoded))
        let again = try #require(link.receive(decoded))

        #expect(saved === again)
        #expect(saved.id == finished.workout.id)
        #expect(saved.title == "Heavy Push")
        #expect(saved.duration == 2700)
        #expect(saved.orderedExercises.first?.orderedSets.map { $0.weight } == [185, 205])
        #expect(try context.fetch(FetchDescriptor<Workout>()).count == 1)
        let after = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: nil, now: now, sortOrder: .name)
        #expect(after.workoutsThisWeek == before.workoutsThisWeek + 1)
        #expect(after.allTemplates.isEmpty) // no templates in this store; the count is what changed
    }

    @Test("User info without a finished workout, or with one that will not decode, is ignored")
    func ignoresBadPayloads() throws {
        #expect(PhoneWatchLink.finishedWorkout(in: [:]) == nil)
        #expect(PhoneWatchLink.finishedWorkout(in: [WatchSnapshot.contextKey: Data("x".utf8)]) == nil)
        #expect(PhoneWatchLink.finishedWorkout(in: [WatchSnapshot.finishedKey: Data("not json".utf8)]) == nil)
        #expect(PhoneWatchLink.finishedWorkout(in: [WatchSnapshot.finishedKey: "a string, not data"]) == nil)
    }

    @Test("An exercise the phone has never seen becomes a custom exercise when the watch's workout is saved")
    func unknownExercise() throws {
        let container = try TestSupport.makeContainer()
        let link = makeLink(container: container)
        let live = LiveWorkout(title: "Odd", startedAt: Date().addingTimeInterval(-600), exercises: [
            LiveExercise(name: "Zercher Squat", bodyPart: "Legs", sets: [LiveSet(reps: 5, weight: 135, isCompleted: true)])
        ])

        let saved = try #require(link.receive(live.finished(at: Date())))

        let exercise = try #require(saved.orderedExercises.first?.exercise)
        #expect(exercise.name == "Zercher Squat")
        #expect(!exercise.isBuiltIn)
        #expect(try container.mainContext.fetch(FetchDescriptor<Exercise>()).count == 1)
    }
}
