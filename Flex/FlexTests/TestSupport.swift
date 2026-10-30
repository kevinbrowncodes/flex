import Foundation
import SwiftData
import Testing
@testable import Flex

/// Helpers shared by the unit tests.
@MainActor
enum TestSupport {
    /// A fresh in-memory container with the app's schema.
    static func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: FlexKeyApp.schema, configurations: [configuration])
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components)!
    }

    /// Builds and inserts a saved workout with one exercise and the given (weight, reps) sets.
    @discardableResult
    static func insertWorkout(
        title: String = "Workout",
        date: Date,
        exercise: Exercise,
        sets: [(weight: Double?, reps: Int?)],
        into context: ModelContext
    ) -> Workout {
        let exerciseSets = sets.enumerated().map { index, set in
            ExerciseSet(setNumber: index + 1, reps: set.reps, weight: set.weight)
        }
        let workoutExercise = WorkoutExercise(exercise: exercise, sets: exerciseSets)
        let workout = Workout(title: title, date: date, duration: 3600, exercises: [workoutExercise])
        context.insert(workout)
        return workout
    }
}
