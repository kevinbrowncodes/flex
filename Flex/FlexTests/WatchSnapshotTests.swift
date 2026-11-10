import Foundation
import SwiftData
import Testing
@testable import Flex

/// What the phone sends the watch, built from SwiftData, and how the watch starts a workout from it (STORY_005).
@MainActor
struct WatchSnapshotTests {
    /// The demo data (library, folders, templates, eight weeks of push/pull/legs) as of a Wednesday noon.
    /// Returns the container, not its context: a context whose container has been released traps
    /// inside SwiftData on its next call, so every test keeps the container in scope.
    private func sampleContainer(now: Date) throws -> ModelContainer {
        let container = try TestSupport.makeContainer()
        let context = container.mainContext
        PreviewData.insertSampleData(into: context)
        DemoHistory.insert(into: context, now: now)
        try context.save()
        return container
    }

    @Test("The builder mirrors the Workout tab and fills last weights from history")
    func builder() throws {
        let now = TestSupport.date(2026, 10, 28, hour: 12)
        let container = try sampleContainer(now: now)
        let context = container.mainContext
        let bench = try #require(try context.fetch(FetchDescriptor<Exercise>()).first { $0.name == "Bench Press (Barbell)" })
        TestSupport.insertWorkout(title: "This week", date: TestSupport.date(2026, 10, 27, hour: 10), exercise: bench, sets: [(190, 5)], into: context)
        TestSupport.insertWorkout(title: "Last week", date: TestSupport.date(2026, 10, 20, hour: 10), exercise: bench, sets: [(100, 5)], into: context)
        TestSupport.insertWorkout(title: "Later today", date: TestSupport.date(2026, 10, 28, hour: 18), exercise: bench, sets: [(300, 1)], into: context)
        try context.save()

        let snapshot = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 4, restSeconds: 60, userName: "Kev", now: now, sortOrder: .name)

        #expect(snapshot.madeAt == now)
        #expect(snapshot.weeklyTarget == 4)
        #expect(snapshot.restSeconds == 60)
        #expect(snapshot.userName == "Kev")
        // Yesterday counts; last week and later today do not. Two sample workouts are dated from the
        // real clock, so the count is checked against the data, not a fixed number.
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: now)!.start
        let expectedThisWeek = try context.fetch(FetchDescriptor<Workout>()).filter { $0.date >= weekStart && $0.date <= now }.count
        #expect(snapshot.workoutsThisWeek == expectedThisWeek)
        #expect(expectedThisWeek >= 1)
        #expect(snapshot.folders.map { $0.name } == ["Bodybuilding", "Crossfit", "Heavy Duty", "Powerlifting"])
        let heavyDuty = try #require(snapshot.folders.first { $0.name == "Heavy Duty" })
        #expect(heavyDuty.templates.map { $0.name } == ["Heavy Legs", "Heavy Pull", "Heavy Push"])
        #expect(snapshot.templates.map { $0.name } == ["Deadlift Day", "Full Body Workout"])
        #expect(!snapshot.templates.contains { $0.folderName != nil })

        let push = try #require(snapshot.allTemplates.first { $0.name == "Heavy Push" })
        #expect(snapshot.template(withID: push.id) == push)
        #expect(push.folderName == "Heavy Duty")
        let first = try #require(push.exercises.first)
        #expect(first.name == "Bench Press (Barbell)")
        #expect(first.barType == .olympicBarbell)
        #expect(first.plannedSets.map { $0.weight } == [185, 205])
        #expect(first.plannedSets.map { $0.reps } == [8, 6])
        // The most recent saved bench press before now is yesterday's 190 × 5, not the demo history.
        #expect(first.previousSets.map { $0.weight } == [190])
        #expect(first.lastSummary == "190 × 5")

        let fullBody = try #require(snapshot.templates.first { $0.name == "Full Body Workout" })
        #expect(fullBody.exercises.allSatisfy { $0.plannedSets.isEmpty })
    }

    @Test("Sorting by date follows the Workout tab's other order")
    func builderByDate() throws {
        let now = TestSupport.date(2026, 10, 28, hour: 12)
        let container = try sampleContainer(now: now)
        let context = container.mainContext
        let byName = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: nil, now: now, sortOrder: .name)
        let byDate = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: nil, now: now, sortOrder: .dateCreated)
        let folder = try #require(try context.fetch(FetchDescriptor<TemplateFolder>()).first { $0.name == "Heavy Duty" })
        let heavyDutyByName = try #require(byName.folders.first { $0.name == "Heavy Duty" })
        let heavyDutyByDate = try #require(byDate.folders.first { $0.name == "Heavy Duty" })

        #expect(heavyDutyByName.templates.map { $0.name } == TemplateSortOrder.name.sort(folder.templatesArray).map { $0.name })
        #expect(heavyDutyByDate.templates.map { $0.name } == TemplateSortOrder.dateCreated.sort(folder.templatesArray).map { $0.name })
        #expect(Set(heavyDutyByName.templates.map { $0.id }) == Set(heavyDutyByDate.templates.map { $0.id }))
        #expect(byName.sameContent(as: byName))
        var later = byName
        later.madeAt = now.addingTimeInterval(60)
        #expect(byName.sameContent(as: later))
        later.workoutsThisWeek += 1
        #expect(!byName.sameContent(as: later))
    }

    @Test("A snapshot round-trips through JSON, and sparse JSON still decodes")
    func codable() throws {
        let now = TestSupport.date(2026, 10, 28, hour: 12)
        let container = try sampleContainer(now: now)
        let context = container.mainContext
        let snapshot = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: "Ashton", now: now, sortOrder: .name)

        let data = try FlexJSON.encoder.encode(snapshot)
        #expect(try FlexJSON.decoder.decode(WatchSnapshot.self, from: data) == snapshot)

        let sparse = """
        {"folders":[{"id":"9A7C0D1E-2B3F-4A5C-8D9E-000000000010","name":"Odd"}],
         "templates":[{"id":"9A7C0D1E-2B3F-4A5C-8D9E-000000000001","name":"Push",
                       "exercises":[{"name":"Dip"}]}]}
        """
        let decoded = try FlexJSON.decoder.decode(WatchSnapshot.self, from: Data(sparse.utf8))
        #expect(decoded.folders[0].templates.isEmpty)
        #expect(decoded.templates[0].exercises[0].bodyPart == "")
        #expect(decoded.templates[0].exercises[0].plannedSets.isEmpty)
        #expect(decoded.templates[0].exercises[0].lastSummary == nil)
        #expect(decoded.workoutsThisWeek == 0)
        #expect(decoded.weeklyTarget == 3)
        #expect(decoded.restSeconds == RestTimer.defaultSeconds)
        #expect(decoded.allTemplates.count == 1)
    }

    @Test("A live workout from a snapshot template matches the phone's start, with fresh ids each time")
    func liveWorkoutFromTemplate() throws {
        let now = TestSupport.date(2026, 10, 28, hour: 12)
        let container = try sampleContainer(now: now)
        let context = container.mainContext
        let snapshot = try WatchSnapshotBuilder.make(context: context, weeklyTarget: 3, restSeconds: 90, userName: nil, now: now, sortOrder: .name)
        let pushTemplate = try #require(context.fetch(FetchDescriptor<WorkoutTemplate>()).first { $0.name == "Heavy Push" })
        let pushSnapshot = try #require(snapshot.template(withID: pushTemplate.id))
        let fullBody = try #require(snapshot.templates.first { $0.name == "Full Body Workout" })

        let fromPhone = LiveWorkoutBridge.start(from: pushTemplate, at: now, restSeconds: 90)
        let fromWatch = LiveWorkout(from: pushSnapshot, at: now, restSeconds: 90)
        let again = LiveWorkout(from: pushSnapshot, at: now, restSeconds: 90)

        #expect(fromWatch.title == fromPhone.title)
        #expect(fromWatch.templateName == "Heavy Push")
        #expect(fromWatch.restSeconds == 90)
        #expect(fromWatch.exercises.map { $0.name } == fromPhone.exercises.map { $0.name })
        #expect(fromWatch.exercises.map { $0.sets.map { $0.weight } } == fromPhone.exercises.map { $0.sets.map { $0.weight } })
        #expect(fromWatch.exercises.map { $0.previousSets.map { $0.weight } } == fromPhone.exercises.map { $0.previousSets.map { $0.weight } })
        #expect(fromWatch.id != again.id)
        #expect(Set(fromWatch.exercises.map { $0.id }).isDisjoint(with: again.exercises.map { $0.id }))
        #expect(Set(fromWatch.allSets.map { $0.id }).isDisjoint(with: again.allSets.map { $0.id }))

        let empty = LiveWorkout(from: fullBody, at: now, restSeconds: 0)
        #expect(empty.exercises.allSatisfy { $0.sets.count == 1 && $0.sets[0].isEmpty })
        #expect(empty.restSeconds == 0)
    }
}
