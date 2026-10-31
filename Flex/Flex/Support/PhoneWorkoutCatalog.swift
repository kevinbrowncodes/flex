import Foundation
import SwiftData

/// The phone's answer to Siri (STORY_010): every exercise in the library that is not archived,
/// those in the live workout first, and the rest default from Settings.
@MainActor
final class PhoneWorkoutCatalog: WorkoutCatalog {
    private let container: ModelContainer
    private let session: LiveWorkoutSession
    private let preferences: PreferencesManager

    init(container: ModelContainer, session: LiveWorkoutSession, preferences: PreferencesManager) {
        self.container = container
        self.session = session
        self.preferences = preferences
    }

    var restSeconds: TimeInterval { preferences.restSeconds }

    /// The library as catalog exercises, archived ones left out, in name order.
    func all() -> [CatalogExercise] {
        let exercises = (try? container.mainContext.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))) ?? []
        return exercises
            .filter { !$0.isArchived }
            .map { CatalogExercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType) }
    }

    private var inWorkout: Set<String> {
        Set((session.workout?.exercises ?? []).map { ExerciseName.normalized($0.name) })
    }

    func exercises(matching query: String) async -> [CatalogExercise] {
        CatalogRanking.rank(all(), matching: query, inWorkout: inWorkout)
    }

    func exercise(id: String) async -> CatalogExercise? {
        all().first { $0.id == id }
    }

    /// What is being done now, else the start of the library.
    func suggestedExercises() async -> [CatalogExercise] {
        if let workout = session.workout, !workout.exercises.isEmpty {
            return workout.exercises.map { CatalogExercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType) }
        }
        return Array(all().prefix(10))
    }
}
