import Foundation
import Testing
@testable import FlexWatch

/// The numbers the watch face shows (STORY_011).
struct WeekProgressTests {
    @Test("Fraction, label, text and met for the usual counts, a zero target, and no snapshot")
    func values() {
        let two = WeekProgress(workoutsThisWeek: 2, weeklyTarget: 3)
        #expect(two.fraction == 2.0 / 3.0)
        #expect(two.label == "2/3")
        #expect(two.text == "2 of 3 workouts this week")
        #expect(!two.isMet)

        let met = WeekProgress(workoutsThisWeek: 3, weeklyTarget: 3)
        #expect(met.fraction == 1)
        #expect(met.isMet)

        let over = WeekProgress(workoutsThisWeek: 5, weeklyTarget: 3)
        #expect(over.fraction == 1) // clamped
        #expect(over.isMet)
        #expect(over.label == "5/3")

        let none = WeekProgress(workoutsThisWeek: 0, weeklyTarget: 3)
        #expect(none.fraction == 0)
        #expect(!none.isMet)

        let zeroTarget = WeekProgress(workoutsThisWeek: 2, weeklyTarget: 0)
        #expect(zeroTarget.fraction == 0)
        #expect(!zeroTarget.isMet)
        #expect(WeekProgress(workoutsThisWeek: 1, weeklyTarget: -4).weeklyTarget == 0)

        let one = WeekProgress(workoutsThisWeek: 1, weeklyTarget: 1)
        #expect(one.text == "1 of 1 workout this week")

        #expect(WeekProgress.empty.label == "–/3")
        #expect(WeekProgress.empty.fraction == 0)
        #expect(!WeekProgress.empty.isMet)
        #expect(WeekProgress.empty.text == "Open Flex on your iPhone")
    }

    @Test("A snapshot's numbers round-trip through shared defaults; nothing stored reads as empty")
    func sharedDefaults() throws {
        let suite = "test.weekprogress.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(WeekProgress.read(from: defaults) == .empty)

        let snapshot = WatchSnapshot(workoutsThisWeek: 2, weeklyTarget: 4)
        WeekProgress(snapshot: snapshot).write(to: defaults)
        #expect(WeekProgress.read(from: defaults) == WeekProgress(workoutsThisWeek: 2, weeklyTarget: 4))
        #expect(defaults.object(forKey: WeekProgress.madeAtKey) != nil)

        WeekProgress(workoutsThisWeek: nil, weeklyTarget: 5).write(to: defaults)
        #expect(WeekProgress.read(from: defaults) == WeekProgress(workoutsThisWeek: nil, weeklyTarget: 5))
    }
}
