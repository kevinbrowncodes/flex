import Foundation
import SwiftData

#if DEBUG
/// Launch-environment hook used by UI tests and App Store screenshot capture. Compiled out of Release.
///
/// - `FLEX_DEMO=sample` (or `1`): in-memory store filled with realistic sample data, signed in, welcome dismissed.
/// - `FLEX_DEMO=empty`: in-memory store with only the bundled exercise library.
/// - `FLEX_THEME=Light|Dark|System`, `FLEX_TAB=profile|history|exercises|workout`, `FLEX_USER_NAME=…`,
///   `FLEX_DEMO_WORKOUT_OFFSET=-2460` (seconds; makes a new workout look like it started 41 minutes ago).
struct DemoMode: Sendable {
    enum Dataset: Sendable {
        case sample
        case empty
    }

    let dataset: Dataset
    let theme: String?
    let initialTab: String?
    let userName: String
    /// Seconds added to a new workout's start time (negative = "started a while ago"), for screenshots.
    let workoutStartOffset: TimeInterval

    static let current = DemoMode(environment: ProcessInfo.processInfo.environment)

    init?(environment: [String: String]) {
        guard let value = environment["FLEX_DEMO"]?.lowercased(), !value.isEmpty, value != "0" else {
            return nil
        }
        dataset = value == "empty" ? .empty : .sample
        theme = environment["FLEX_THEME"]
        initialTab = environment["FLEX_TAB"]?.lowercased()
        userName = environment["FLEX_USER_NAME"] ?? "Alex"
        workoutStartOffset = environment["FLEX_DEMO_WORKOUT_OFFSET"].flatMap(TimeInterval.init) ?? 0
    }

    @MainActor
    func makeModelContainer(schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        switch dataset {
        case .empty:
            try ExerciseLibrary.synchronize(context: container.mainContext)
        case .sample:
            PreviewData.insertSampleData(into: container.mainContext)
            DemoHistory.insert(into: container.mainContext)
            try container.mainContext.save()
        }
        return container
    }

    @MainActor
    func apply(auth: AuthenticationManager, preferences: PreferencesManager) {
        auth.isAuthenticated = true
        auth.userIdentifier = "demo-user"
        auth.userFullName = userName
        preferences.hasSeenWelcome = true
        preferences.userName = userName
        preferences.workoutTarget = 3
        preferences.dailyTarget = 1
    }
}

/// Generates eight weeks of push/pull/legs history so charts, "Previous" columns and PR badges have data.
enum DemoHistory {
    @MainActor
    static func insert(into context: ModelContext, now: Date = Date()) {
        let calendar = Calendar.current
        guard let templates = try? context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.name)])) else { return }
        let cycle = ["Heavy Push", "Heavy Pull", "Heavy Legs"].compactMap { name in templates.first { $0.name == name } }
        guard !cycle.isEmpty else { return }

        var cycleIndex = 0
        for weeksAgo in stride(from: 8, through: 1, by: -1) {
            for weekday in [2, 4, 6] { // Monday, Wednesday, Friday
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                      let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart),
                      let day = calendar.date(byAdding: .day, value: weekday - 1, to: interval.start),
                      let date = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: day),
                      date < now else { continue }

                let template = cycle[cycleIndex % cycle.count]
                cycleIndex += 1

                // Progressive overload: older weeks are a little lighter than the template's working weights.
                let scale = 1.0 - Double(weeksAgo) * 0.025
                let exercises = template.templateExercisesArray
                    .sorted { $0.order < $1.order }
                    .compactMap { templateExercise -> WorkoutExercise? in
                        guard let exercise = templateExercise.exercise else { return nil }
                        let sets = templateExercise.setsArray
                            .sorted { $0.setNumber < $1.setNumber }
                            .map { templateSet -> ExerciseSet in
                                let weight = templateSet.weight.map { (($0 * scale) / 5).rounded() * 5 }
                                let set = ExerciseSet(setNumber: templateSet.setNumber, reps: templateSet.reps, weight: weight)
                                set.isCompleted = true
                                return set
                            }
                        return WorkoutExercise(exercise: exercise, sets: sets)
                    }

                let workout = Workout(
                    title: template.name,
                    date: date,
                    duration: TimeInterval(50 * 60 + (weekday * 137) % 900),
                    exercises: exercises
                )
                context.insert(workout)
            }
        }
    }
}
#endif
