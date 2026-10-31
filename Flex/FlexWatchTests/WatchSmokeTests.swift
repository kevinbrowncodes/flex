import Foundation
import Testing
@testable import FlexWatch

/// The shared workout code runs in the watch module, and the demo hook reads its environment (STORY_004).
struct WatchSmokeTests {
    @Test("The shared live workout applies an edit on watchOS")
    func sharedModelRuns() {
        let set = LiveSet(reps: 8, weight: 185)
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var workout = LiveWorkout(
            title: "Push",
            startedAt: start,
            exercises: [LiveExercise(name: "Bench Press (Barbell)", bodyPart: "Chest", sets: [set])],
            restSeconds: 90
        )

        workout.apply(.setCompleted(setID: set.id, isCompleted: true), at: start.addingTimeInterval(100))

        #expect(workout.set(withID: set.id)?.isCompleted == true)
        #expect(workout.restRemaining(at: start.addingTimeInterval(130)) == 60)
        #expect(Formatting.timer(workout.restRemaining(at: start.addingTimeInterval(130)) ?? 0) == "1:00")
    }

    @Test("Watch demo mode only activates from the launch environment")
    func demoMode() {
        #expect(WatchDemoMode(environment: [:]) == nil)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "0"]) == nil)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "empty"])?.dataset == .empty)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "1"])?.dataset == .sample)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "1"])?.resumesLiveWorkout == false)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "sample", "FLEX_DEMO_RESUME": "1"])?.resumesLiveWorkout == true)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "1"])?.workoutStartOffset == 0)
        #expect(WatchDemoMode(environment: ["FLEX_DEMO": "1", "FLEX_DEMO_WORKOUT_OFFSET": "-2472"])?.workoutStartOffset == -2472)
    }
}
