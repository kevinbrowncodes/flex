import Foundation
import SwiftData

/// Keeps the on-device exercise library in step with the bundled `Exercises.json`
/// and repairs duplicates that CloudKit can introduce when two devices seed the library independently.
enum ExerciseLibrary {
    struct SyncResult: Equatable {
        var inserted = 0
        var duplicatesMerged = 0
    }

    /// Seeds the library on first launch, otherwise merges duplicates and adds any new bundled exercises.
    @discardableResult
    static func synchronize(context: ModelContext, bundled: [Exercise]? = nil) throws -> SyncResult {
        let bundledExercises = bundled ?? Exercise.loadFromBundle()
        var result = SyncResult()

        let existing = try context.fetch(FetchDescriptor<Exercise>())
        if existing.isEmpty {
            for exercise in bundledExercises {
                context.insert(exercise)
            }
            result.inserted = bundledExercises.count
        } else {
            let merge = mergeDuplicates(in: existing, context: context)
            result.duplicatesMerged = merge.removed
            let existingNames = Set(merge.survivors.map { normalized($0.name) })
            for exercise in bundledExercises where !existingNames.contains(normalized(exercise.name)) {
                context.insert(exercise)
                result.inserted += 1
            }
        }

        if context.hasChanges {
            try context.save()
        }
        return result
    }

    /// Merges exercises that share a name, re-pointing workout and template references at the survivor.
    /// Returns the number of exercises removed.
    @discardableResult
    static func mergeDuplicates(context: ModelContext) throws -> Int {
        let all = try context.fetch(FetchDescriptor<Exercise>())
        let removed = mergeDuplicates(in: all, context: context).removed
        if removed > 0 {
            try context.save()
        }
        return removed
    }

    private static func mergeDuplicates(in exercises: [Exercise], context: ModelContext) -> (removed: Int, survivors: [Exercise]) {
        let groups = Dictionary(grouping: exercises) { normalized($0.name) }
        var removed = 0
        var survivors: [Exercise] = []

        for (_, copies) in groups {
            guard copies.count > 1 else {
                survivors.append(copies[0])
                continue
            }
            let keeper = preferredKeeper(among: copies)
            survivors.append(keeper)

            for loser in copies where loser !== keeper {
                for workoutExercise in loser.workoutExercises ?? [] {
                    workoutExercise.exercise = keeper
                }
                for templateExercise in loser.templateExercises ?? [] {
                    templateExercise.exercise = keeper
                }
                if keeper.barType == nil, let barType = loser.barType {
                    keeper.barType = barType
                }
                context.delete(loser)
                removed += 1
            }
        }
        return (removed, survivors)
    }

    /// Built-in copies win over custom ones; then the copy with the most history; then the first seen.
    static func preferredKeeper(among copies: [Exercise]) -> Exercise {
        var best = copies[0]
        for candidate in copies.dropFirst() {
            if candidate.isBuiltIn != best.isBuiltIn {
                if candidate.isBuiltIn { best = candidate }
            } else if candidate.referenceCount > best.referenceCount {
                best = candidate
            }
        }
        return best
    }

    /// The key duplicates are merged on; the same key a live workout names its exercises by.
    static func normalized(_ name: String) -> String {
        ExerciseName.normalized(name)
    }
}
