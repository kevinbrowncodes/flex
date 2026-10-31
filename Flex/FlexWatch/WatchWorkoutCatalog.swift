import Foundation

/// The watch's answer to Siri (STORY_010): every exercise the phone's snapshot names, those in the
/// live workout first, and the snapshot's rest default.
@MainActor
final class WatchWorkoutCatalog: WorkoutCatalog {
    private let state: WatchState
    private let session: LiveWorkoutSession

    init(state: WatchState, session: LiveWorkoutSession) {
        self.state = state
        self.session = session
    }

    var restSeconds: TimeInterval {
        state.snapshot?.restSeconds ?? RestTimer.defaultSeconds
    }

    /// Every exercise in every template, plus the live workout's, each once.
    func all() -> [CatalogExercise] {
        let fromTemplates = (state.snapshot?.allTemplates ?? []).flatMap { template in
            template.exercises.map { CatalogExercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType) }
        }
        let fromWorkout = (session.workout?.exercises ?? []).map { CatalogExercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType) }
        return CatalogRanking.rank(fromWorkout + fromTemplates, matching: "", inWorkout: inWorkout)
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

    func suggestedExercises() async -> [CatalogExercise] {
        if let workout = session.workout, !workout.exercises.isEmpty {
            return workout.exercises.map { CatalogExercise(name: $0.name, bodyPart: $0.bodyPart, category: $0.category, barType: $0.barType) }
        }
        return Array(all().prefix(10))
    }
}
