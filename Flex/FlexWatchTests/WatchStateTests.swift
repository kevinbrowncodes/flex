import Foundation
import Testing
@testable import FlexWatch

/// The watch keeps the phone's snapshot and shows the sample one in demo launches (STORY_005).
@MainActor
struct WatchStateTests {
    private func temporaryStore() -> JSONFileStore<WatchSnapshot> {
        JSONFileStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json"))
    }

    @Test("The store saves, loads and clears a snapshot")
    func store() throws {
        let store = temporaryStore()
        defer { store.clear() }
        #expect(store.load() == nil)
        try store.save(WatchSnapshot.sample)
        #expect(store.load() == WatchSnapshot.sample)
        store.clear()
        #expect(store.load() == nil)
    }

    @Test("A received snapshot is published and survives a relaunch")
    func receive() {
        let store = temporaryStore()
        defer { store.clear() }
        let state = WatchState(store: store)
        #expect(state.snapshot == nil)

        state.receive(.sample)
        #expect(state.snapshot == WatchSnapshot.sample)

        let relaunched = WatchState(store: store)
        #expect(relaunched.snapshot == WatchSnapshot.sample)

        relaunched.clear()
        #expect(WatchState(store: store).snapshot == nil)
    }

    @Test("A received snapshot leaves this week's numbers in the shared defaults and asks for a redraw")
    func sharesWeekProgress() throws {
        let suite = "test.watchstate.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let state = WatchState(store: nil, sharedDefaults: defaults)
        var reloads = 0
        state.reloadWidgets = { reloads += 1 }
        #expect(WeekProgress.read(from: defaults) == .empty)

        state.receive(.sample)

        #expect(WeekProgress.read(from: defaults) == WeekProgress(workoutsThisWeek: 2, weeklyTarget: 3))
        #expect(reloads == 1)

        // A snapshot the app starts with (stored or initial) is shared too, without a redraw request.
        let started = WatchState(store: nil, initial: .sample, sharedDefaults: defaults)
        #expect(started.snapshot == WatchSnapshot.sample)
        #expect(WeekProgress.read(from: defaults).workoutsThisWeek == 2)
    }

    @Test("A demo launch starts from the sample, or from nothing")
    func demoStarts() {
        #expect(WatchState(store: nil, initial: .sample).snapshot == WatchSnapshot.sample)
        #expect(WatchState(store: nil).snapshot == nil)
    }

    @Test("The sample snapshot is the phone's Heavy Duty folder with last weights")
    func sample() throws {
        let sample = WatchSnapshot.sample
        #expect(sample.folders.map { $0.name } == ["Heavy Duty"])
        #expect(sample.folders[0].templates.map { $0.name } == ["Heavy Push", "Heavy Pull", "Heavy Legs"])
        #expect(sample.templates.map { $0.name } == ["Full Body Workout"])
        #expect(sample.workoutsThisWeek == 2)
        #expect(sample.weeklyTarget == 3)
        let push = try #require(sample.allTemplates.first)
        #expect(push.exercises[0].name == "Bench Press (Barbell)")
        #expect(push.exercises[0].lastSummary == "205 × 6") // the heaviest of last time's sets
        let legs = try #require(sample.allTemplates.first { $0.name == "Heavy Legs" })
        #expect(legs.exercises.first { $0.name == "Leg Extension (Machine)" }?.lastSummary == nil)
        #expect(sample.template(withID: push.id) == push)
        #expect(sample.allTemplates.count == 4)
    }
}
