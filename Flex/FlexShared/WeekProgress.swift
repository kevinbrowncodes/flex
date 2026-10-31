import Foundation

/// The number the watch face shows (STORY_011): workouts this week against the weekly target. The
/// watch app writes it into the App Group after every snapshot; the widget reads only this.
struct WeekProgress: Equatable, Sendable {
    static let appGroup = "group.kevinbrowncodes.Flex"
    static let workoutsKey = "weekProgress.workouts"
    static let targetKey = "weekProgress.target"
    static let madeAtKey = "weekProgress.madeAt"

    /// nil until the phone has sent a snapshot.
    var workoutsThisWeek: Int?
    var weeklyTarget: Int

    init(workoutsThisWeek: Int?, weeklyTarget: Int) {
        self.workoutsThisWeek = workoutsThisWeek
        self.weeklyTarget = max(0, weeklyTarget)
    }

    init(snapshot: WatchSnapshot) {
        self.init(workoutsThisWeek: snapshot.workoutsThisWeek, weeklyTarget: snapshot.weeklyTarget)
    }

    /// Before any snapshot: a dash over the default target.
    static let empty = WeekProgress(workoutsThisWeek: nil, weeklyTarget: 3)

    /// How full the ring is, 0 to 1.
    var fraction: Double {
        guard let workoutsThisWeek, weeklyTarget > 0 else { return 0 }
        return min(1, max(0, Double(workoutsThisWeek) / Double(weeklyTarget)))
    }

    var isMet: Bool {
        guard let workoutsThisWeek, weeklyTarget > 0 else { return false }
        return workoutsThisWeek >= weeklyTarget
    }

    /// "2/3", or "–/3" with no snapshot.
    var label: String {
        "\(workoutsThisWeek.map(String.init) ?? "–")/\(weeklyTarget)"
    }

    /// "2 of 3 workouts this week".
    var text: String {
        guard let workoutsThisWeek else { return "Open Flex on your iPhone" }
        return "\(workoutsThisWeek) of \(weeklyTarget) workout\(weeklyTarget == 1 ? "" : "s") this week"
    }

    func write(to defaults: UserDefaults, at date: Date = Date()) {
        defaults.set(workoutsThisWeek ?? -1, forKey: Self.workoutsKey)
        defaults.set(weeklyTarget, forKey: Self.targetKey)
        defaults.set(date.timeIntervalSinceReferenceDate, forKey: Self.madeAtKey)
    }

    static func read(from defaults: UserDefaults) -> WeekProgress {
        guard defaults.object(forKey: targetKey) != nil else { return .empty }
        let workouts = defaults.integer(forKey: workoutsKey)
        return WeekProgress(workoutsThisWeek: workouts < 0 ? nil : workouts, weeklyTarget: defaults.integer(forKey: targetKey))
    }
}
