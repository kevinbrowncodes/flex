import Foundation
import Testing
@testable import FlexWatch

/// The watch's catalog for Siri: the snapshot's exercises, each once, the live workout first (STORY_010).
@MainActor
struct WatchCatalogTests {
    @Test("The sample snapshot answers Siri: both bench presses, no duplicates, the live workout first")
    func catalog() async {
        let state = WatchState(store: nil, initial: .sample)
        let session = LiveWorkoutSession(store: nil, resume: false)
        let catalog = WatchWorkoutCatalog(state: state, session: session)

        let all = catalog.all()
        #expect(Set(all.map { $0.id }).count == all.count) // Bench Press is in two templates, listed once
        #expect(await catalog.exercises(matching: "bench press").map { $0.name } == ["Bench Press (Barbell)", "Incline Bench Press (Barbell)"])
        #expect(await catalog.exercise(id: "Squat (Barbell)")?.bodyPart == "Legs")
        #expect(await catalog.exercise(id: "Nothing") == nil)
        #expect(await catalog.restSeconds == 90)

        session.start(LiveWorkout(from: WatchSnapshot.sample.allTemplates[1], restSeconds: 90)) // Heavy Pull
        let suggested = await catalog.suggestedExercises()
        #expect(suggested.first?.name == "Deadlift (Barbell)") // in the workout's own order
        // A search puts the live workout's exercises first, by name within that group.
        let ranked = await catalog.exercises(matching: "")
        #expect(ranked.first?.name == "Bent Over Row (Barbell)")
        #expect(Array(ranked.prefix(4)).map { $0.name } == ["Bent Over Row (Barbell)", "Bicep Curl (Dumbbell)", "Deadlift (Barbell)", "Lat Pulldown (Cable)"])

        let empty = WatchWorkoutCatalog(state: WatchState(store: nil), session: LiveWorkoutSession(store: nil, resume: false))
        #expect(await empty.exercises(matching: "bench").isEmpty)
        #expect(await empty.restSeconds == RestTimer.defaultSeconds)
    }
}
