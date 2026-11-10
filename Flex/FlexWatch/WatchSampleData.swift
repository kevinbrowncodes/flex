import Foundation

#if DEBUG
/// The snapshot a `FLEX_DEMO=sample` launch installs, so watch UI tests, previews and screenshots
/// need no phone: the phone's sample Heavy Duty folder and Full Body template, with last weights
/// (STORY_005). Fixed ids so navigation is stable between launches.
extension WatchSnapshot {
    static let sample: WatchSnapshot = {
        func id(_ last: Int) -> UUID {
            UUID(uuidString: String(format: "9A7C0D1E-2B3F-4A5C-8D9E-%012d", last))!
        }
        func exercise(_ name: String, _ bodyPart: String, bar: BarType? = nil, planned: [(reps: Int, weight: Double)], previous: [(reps: Int, weight: Double)]) -> SnapshotExercise {
            SnapshotExercise(
                name: name,
                bodyPart: bodyPart,
                barType: bar,
                plannedSets: planned.map { SnapshotSet(reps: $0.reps, weight: $0.weight) },
                previousSets: previous.map { LiveSet(reps: $0.reps, weight: $0.weight, isCompleted: true) }
            )
        }

        let push = SnapshotTemplate(id: id(1), name: "Heavy Push", folderName: "Heavy Duty", exercises: [
            exercise("Bench Press (Barbell)", "Chest", bar: .olympicBarbell, planned: [(8, 185), (6, 205)], previous: [(8, 185), (6, 205)]),
            exercise("Incline Bench Press (Barbell)", "Chest", bar: .olympicBarbell, planned: [(8, 155), (6, 175)], previous: [(8, 155), (6, 170)]),
            exercise("Shoulder Press (Dumbbell)", "Shoulders", planned: [(8, 95)], previous: [(8, 90)]),
            exercise("Lateral Raise (Dumbbell)", "Shoulders", planned: [(12, 25)], previous: [(12, 25)]),
            exercise("Dips", "Chest", planned: [(10, 0)], previous: [(10, 0)])
        ])
        let pull = SnapshotTemplate(id: id(2), name: "Heavy Pull", folderName: "Heavy Duty", exercises: [
            exercise("Deadlift (Barbell)", "Back", bar: .olympicBarbell, planned: [(6, 315), (4, 365)], previous: [(6, 315), (4, 355)]),
            exercise("Bent Over Row (Barbell)", "Back", bar: .olympicBarbell, planned: [(8, 185), (6, 205)], previous: [(8, 185), (6, 205)]),
            exercise("Lat Pulldown (Cable)", "Back", planned: [(10, 140)], previous: [(10, 140)]),
            exercise("Bicep Curl (Dumbbell)", "Arms", planned: [(8, 40)], previous: [(8, 40)])
        ])
        let legs = SnapshotTemplate(id: id(3), name: "Heavy Legs", folderName: "Heavy Duty", exercises: [
            exercise("Squat (Barbell)", "Legs", bar: .olympicBarbell, planned: [(8, 225), (6, 275)], previous: [(8, 225), (6, 265)]),
            exercise("Leg Press (Machine)", "Legs", planned: [(12, 360), (10, 400)], previous: [(12, 360), (10, 400)]),
            exercise("Leg Extension (Machine)", "Legs", planned: [(15, 120)], previous: []),
            exercise("Calf Raise (Machine)", "Legs", planned: [(15, 200)], previous: [(15, 200)])
        ])
        let fullBody = SnapshotTemplate(id: id(4), name: "Full Body Workout", folderName: nil, exercises: [
            exercise("Bench Press (Barbell)", "Chest", bar: .olympicBarbell, planned: [], previous: [(8, 185), (6, 205)]),
            exercise("Squat (Barbell)", "Legs", bar: .olympicBarbell, planned: [], previous: [(8, 225), (6, 265)]),
            exercise("Lat Pulldown (Cable)", "Back", planned: [], previous: [(10, 140)]),
            exercise("Shoulder Press (Dumbbell)", "Shoulders", planned: [], previous: [(8, 90)]),
            exercise("Bicep Curl (Dumbbell)", "Arms", planned: [], previous: [(8, 40)])
        ])

        return WatchSnapshot(
            madeAt: Date(timeIntervalSinceReferenceDate: 814_000_000),
            folders: [SnapshotFolder(id: id(10), name: "Heavy Duty", templates: [push, pull, legs])],
            templates: [fullBody],
            workoutsThisWeek: 2,
            weeklyTarget: 3,
            restSeconds: 90,
            userName: "Ashton"
        )
    }()
}
#endif
