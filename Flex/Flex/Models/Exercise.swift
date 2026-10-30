import Foundation
import SwiftData

@Model
class Exercise {
    var name: String = ""
    var bodyPart: String = ""
    var category: String = "Strength"
    var barType: BarType? = nil
    var isBuiltIn: Bool = false
    /// Soft-delete flag ("Deleted" in the UI): hidden from pickers but kept so workout history stays intact.
    /// Named `isArchived` because `isDeleted` collides with Core Data's own `NSManagedObject.isDeleted`
    /// key under SwiftData, which made the value unreadable after a save.
    var isArchived: Bool = false

    // Inverse relationships for CloudKit
    var workoutExercises: [WorkoutExercise]?
    var templateExercises: [TemplateExercise]?

    static let bodyParts = ["Arms", "Back", "Cardio", "Chest", "Core", "Full Body", "Legs", "Shoulders"]
    static let categories = ["Strength", "Cardio", "Stretching", "Other"]

    init(name: String, bodyPart: String, category: String = "Strength", barType: BarType? = nil, isBuiltIn: Bool = false, isArchived: Bool = false) {
        self.name = name
        self.bodyPart = bodyPart
        self.category = category
        self.barType = barType
        self.isBuiltIn = isBuiltIn
        self.isArchived = isArchived
    }

    var isCardio: Bool {
        bodyPart == "Cardio"
    }

    /// Whether this exercise is loaded on a barbell (shows the plate calculator).
    var usesBarbell: Bool {
        barType != nil || name.localizedCaseInsensitiveContains("(Barbell)")
    }

    /// Number of saved workouts and templates that reference this exercise.
    var referenceCount: Int {
        (workoutExercises ?? []).filter { $0.workout != nil }.count + (templateExercises ?? []).count
    }

    /// The most recent saved performance of this exercise strictly before `date`.
    func mostRecentWorkoutExercise(before date: Date, excluding: WorkoutExercise? = nil) -> WorkoutExercise? {
        (workoutExercises ?? [])
            .filter { candidate in
                guard let workout = candidate.workout else { return false }
                if let excluding, candidate.id == excluding.id { return false }
                return workout.date < date
            }
            .max { ($0.workout?.date ?? .distantPast) < ($1.workout?.date ?? .distantPast) }
    }

    struct BundledExercise: Codable, Equatable {
        let name: String
        let bodyPart: String
        let category: String
        let barType: BarType?
    }

    /// Decodes the bundled exercise library without creating model objects.
    static func loadBundledDefinitions(from bundle: Bundle = .main) -> [BundledExercise] {
        guard let url = bundle.url(forResource: "Exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([BundledExercise].self, from: data)) ?? []
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> [Exercise] {
        loadBundledDefinitions(from: bundle).map {
            Exercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType, isBuiltIn: true)
        }
    }
}
