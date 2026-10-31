import AppIntents
import Foundation

/// What Siri needs from the device it runs on (STORY_010): the exercises it can name, and the rest
/// default for a workout it starts. The phone answers from SwiftData, the watch from its snapshot.
protocol WorkoutCatalog: AnyObject {
    func exercises(matching query: String) async -> [CatalogExercise]
    func exercise(id: String) async -> CatalogExercise?
    func suggestedExercises() async -> [CatalogExercise]
    var restSeconds: TimeInterval { get async }
}

/// The dependency keys both apps register at launch.
enum SiriDependencies {
    static let catalog = "WorkoutCatalog"
}

struct ExerciseEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Exercise"
    static let defaultQuery = ExerciseQuery()

    var id: String
    var name: String

    init(_ exercise: CatalogExercise) {
        id = exercise.id
        name = exercise.name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ExerciseQuery: EntityStringQuery {
    @Dependency(key: SiriDependencies.catalog) private var catalog: any WorkoutCatalog

    func entities(for identifiers: [String]) async throws -> [ExerciseEntity] {
        var found: [ExerciseEntity] = []
        for identifier in identifiers {
            if let exercise = await catalog.exercise(id: identifier) {
                found.append(ExerciseEntity(exercise))
            }
        }
        return found
    }

    func entities(matching string: String) async throws -> [ExerciseEntity] {
        await catalog.exercises(matching: string).map(ExerciseEntity.init)
    }

    func suggestedEntities() async throws -> [ExerciseEntity] {
        await catalog.suggestedExercises().map(ExerciseEntity.init)
    }
}

enum LogSetError: Error, CustomLocalizedStringResourceConvertible {
    case unknownExercise

    var localizedStringResource: LocalizedStringResource {
        "I couldn't find that exercise in Flex."
    }
}

/// "Log bench press in Flex": Siri asks for the weight and reps it was not told, then logs the set
/// in the workout running on this device, or starts one named by the time of day and logs it
/// there (STORY_010). One definition, built into the phone and the watch.
struct LogSetIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a Set"
    static let description = IntentDescription("Logs a set in the workout you are doing, or starts a workout and logs it there.")
    static let openAppWhenRun = false

    @Parameter(title: "Exercise", requestValueDialog: "Which exercise?")
    var exercise: ExerciseEntity

    @Parameter(title: "Weight (lb)", requestValueDialog: "How much weight?")
    var weight: Double

    @Parameter(title: "Reps", requestValueDialog: "How many reps?")
    var reps: Int

    @Dependency private var session: LiveWorkoutSession
    @Dependency(key: SiriDependencies.catalog) private var catalog: any WorkoutCatalog

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$weight) lb × \(\.$reps) on \(\.$exercise)")
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        guard let catalogExercise = await catalog.exercise(id: exercise.id) else {
            throw LogSetError.unknownExercise
        }
        let restSeconds = await catalog.restSeconds
        let result = SetLogger.log(exercise: catalogExercise, weight: weight, reps: reps, into: session.workout, restSeconds: restSeconds)
        if result.startedWorkout {
            session.start(result.workout)
        } else {
            for edit in result.edits {
                session.apply(edit)
            }
        }
        return .result(dialog: "\(result.sentence)")
    }
}

struct FlexShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogSetIntent(),
            phrases: [
                "Log \(\.$exercise) in \(.applicationName)",
                "Log a set in \(.applicationName)"
            ],
            shortTitle: "Log a Set",
            systemImageName: "dumbbell"
        )
    }
}
