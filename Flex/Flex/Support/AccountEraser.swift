import Foundation
import SwiftData

/// Delete Account (STORY_015, BUG_003): erases everything Flex holds for the person. Flex has no
/// server, so "the account" is the Sign in with Apple record and preferences in iCloud key-value
/// storage plus the SwiftData store CloudKit mirrors to the person's private database.
@MainActor
enum AccountEraser {
    /// Deletes every record of every model, one object at a time so CloudKit mirrors each delete
    /// (a batch delete can bypass the mirroring), leaves first so no cascade meets a deleted
    /// object, then re-seeds the bundled exercise library so Flex works after a new sign-in.
    static func eraseData(in context: ModelContext) throws {
        try deleteAll(ExerciseSet.self, in: context)
        try deleteAll(TemplateSet.self, in: context)
        try deleteAll(WorkoutExercise.self, in: context)
        try deleteAll(TemplateExercise.self, in: context)
        try deleteAll(Workout.self, in: context)
        try deleteAll(WorkoutTemplate.self, in: context)
        try deleteAll(TemplateFolder.self, in: context)
        try deleteAll(Exercise.self, in: context)
        try context.save()
        try ExerciseLibrary.synchronize(context: context)
    }

    /// The whole of Delete Account: the workout in progress, the data, the preferences, the
    /// sign-in. Nothing is signed out unless the data was erased.
    static func eraseAccount(
        context: ModelContext,
        session: LiveWorkoutSession,
        preferences: PreferencesManager,
        auth: AuthenticationManager
    ) throws {
        session.discard()
        try eraseData(in: context)
        preferences.reset()
        auth.signOut()
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        for object in try context.fetch(FetchDescriptor<T>()) {
            context.delete(object)
        }
    }
}
