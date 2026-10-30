import Foundation
import SwiftData

/// Builds the watch's snapshot from SwiftData and preferences (STORY_005). Phone only: the
/// watch never reads SwiftData, it reads this.
@MainActor
enum WatchSnapshotBuilder {
    /// The Workout tab's template order, which the watch mirrors.
    static var currentSortOrder: TemplateSortOrder {
        TemplateSortOrder(rawValue: UserDefaults.standard.string(forKey: "templateSortOrder") ?? "") ?? .name
    }

    static func make(
        context: ModelContext,
        weeklyTarget: Int,
        restSeconds: TimeInterval,
        userName: String?,
        now: Date = Date(),
        calendar: Calendar = .current,
        sortOrder: TemplateSortOrder? = nil
    ) throws -> WatchSnapshot {
        let order = sortOrder ?? currentSortOrder
        // Sorted here, not by a key-path SortDescriptor: with more than one ModelContainer in a
        // process (the unit tests make one per test) a key-path sort trapped inside SwiftData.
        let folders = try context.fetch(FetchDescriptor<TemplateFolder>())
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())

        // The same week the Profile's "this week" counts: the calendar week's start up to now.
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let thisWeek = workouts.filter { $0.date >= weekStart && $0.date <= now }.count

        let snapshotFolders = folders.map { folder in
            SnapshotFolder(
                id: folder.id,
                name: folder.name,
                templates: order.sort(folder.templatesArray).map { template(from: $0, folderName: folder.name, before: now) }
            )
        }
        let unfiled = order.sort(templates.filter { $0.templateFolder == nil })
            .map { template(from: $0, folderName: nil, before: now) }

        return WatchSnapshot(
            madeAt: now,
            folders: snapshotFolders,
            templates: unfiled,
            workoutsThisWeek: thisWeek,
            weeklyTarget: weeklyTarget,
            restSeconds: restSeconds,
            userName: userName
        )
    }

    static func template(from template: WorkoutTemplate, folderName: String?, before date: Date) -> SnapshotTemplate {
        let exercises = template.templateExercisesArray
            .sorted { $0.order < $1.order }
            .compactMap { templateExercise -> SnapshotExercise? in
                guard let exercise = templateExercise.exercise else { return nil }
                let planned = templateExercise.setsArray
                    .sorted { $0.setNumber < $1.setNumber }
                    .map { SnapshotSet(reps: $0.reps, weight: $0.weight) }
                return SnapshotExercise(
                    name: exercise.name,
                    bodyPart: exercise.bodyPart,
                    category: exercise.category,
                    barType: exercise.barType,
                    plannedSets: planned,
                    previousSets: LiveWorkoutBridge.previousSets(of: exercise, before: date)
                )
            }
        return SnapshotTemplate(id: template.id, name: template.name, folderName: folderName, exercises: exercises)
    }
}
