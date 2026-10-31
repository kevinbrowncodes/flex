import Foundation

/// What the phone sends the watch so it can start any workout the phone could and show what was
/// lifted last time (STORY_005): template folders and templates with their planned sets, each
/// exercise's previous performance, this week's count against the target, the rest default. The
/// phone is the only writer; the watch holds the latest snapshot and reads from it.
struct WatchSnapshot: Codable, Equatable, Sendable {
    /// The WatchConnectivity application-context key the snapshot travels under.
    static let contextKey = "snapshot"
    /// The user-info keys a finished workout travels back under (STORY_007): the encoded
    /// `FinishedWorkout`, and its workout id as a string so a transfer can be matched to it.
    static let finishedKey = "finishedWorkout"
    static let finishedIDKey = "finishedWorkoutID"

    var madeAt: Date
    /// Folders in name order, each with its templates in the Workout tab's order.
    var folders: [SnapshotFolder]
    /// Templates in no folder, in the Workout tab's order.
    var templates: [SnapshotTemplate]
    var workoutsThisWeek: Int
    var weeklyTarget: Int
    /// Rest after each completed set, in seconds; 0 is off.
    var restSeconds: TimeInterval
    var userName: String?

    init(madeAt: Date = Date(), folders: [SnapshotFolder] = [], templates: [SnapshotTemplate] = [], workoutsThisWeek: Int = 0, weeklyTarget: Int = 3, restSeconds: TimeInterval = RestTimer.defaultSeconds, userName: String? = nil) {
        self.madeAt = madeAt
        self.folders = folders
        self.templates = templates
        self.workoutsThisWeek = workoutsThisWeek
        self.weeklyTarget = weeklyTarget
        self.restSeconds = max(0, restSeconds)
        self.userName = userName
    }

    private enum CodingKeys: String, CodingKey {
        case madeAt, folders, templates, workoutsThisWeek, weeklyTarget, restSeconds, userName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        madeAt = try container.decodeIfPresent(Date.self, forKey: .madeAt) ?? .distantPast
        folders = try container.decodeIfPresent([SnapshotFolder].self, forKey: .folders) ?? []
        templates = try container.decodeIfPresent([SnapshotTemplate].self, forKey: .templates) ?? []
        workoutsThisWeek = try container.decodeIfPresent(Int.self, forKey: .workoutsThisWeek) ?? 0
        weeklyTarget = try container.decodeIfPresent(Int.self, forKey: .weeklyTarget) ?? 3
        restSeconds = max(0, try container.decodeIfPresent(TimeInterval.self, forKey: .restSeconds) ?? RestTimer.defaultSeconds)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
    }

    /// Every template, filed ones first.
    var allTemplates: [SnapshotTemplate] {
        folders.flatMap { $0.templates } + templates
    }

    func template(withID id: UUID) -> SnapshotTemplate? {
        allTemplates.first { $0.id == id }
    }

    /// True when only the time it was made differs, so the phone can skip re-sending it.
    func sameContent(as other: WatchSnapshot) -> Bool {
        var copy = self
        copy.madeAt = other.madeAt
        return copy == other
    }
}

struct SnapshotFolder: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var templates: [SnapshotTemplate]

    init(id: UUID, name: String, templates: [SnapshotTemplate]) {
        self.id = id
        self.name = name
        self.templates = templates
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, templates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        templates = try container.decodeIfPresent([SnapshotTemplate].self, forKey: .templates) ?? []
    }
}

struct SnapshotTemplate: Codable, Equatable, Identifiable, Sendable {
    /// The phone's `WorkoutTemplate.id`.
    var id: UUID
    var name: String
    var folderName: String?
    var exercises: [SnapshotExercise]

    init(id: UUID, name: String, folderName: String? = nil, exercises: [SnapshotExercise]) {
        self.id = id
        self.name = name
        self.folderName = folderName
        self.exercises = exercises
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, folderName, exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        folderName = try container.decodeIfPresent(String.self, forKey: .folderName)
        exercises = try container.decodeIfPresent([SnapshotExercise].self, forKey: .exercises) ?? []
    }
}

/// One exercise in a template as the watch needs it: what is planned and what was done last time.
struct SnapshotExercise: Codable, Equatable, Sendable {
    var name: String
    var bodyPart: String
    var category: String
    var barType: BarType?
    var plannedSets: [SnapshotSet]
    /// The most recent earlier performance, in set order.
    var previousSets: [LiveSet]

    init(name: String, bodyPart: String, category: String = "Strength", barType: BarType? = nil, plannedSets: [SnapshotSet] = [], previousSets: [LiveSet] = []) {
        self.name = name
        self.bodyPart = bodyPart
        self.category = category
        self.barType = barType
        self.plannedSets = plannedSets
        self.previousSets = previousSets
    }

    private enum CodingKeys: String, CodingKey {
        case name, bodyPart, category, barType, plannedSets, previousSets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        bodyPart = try container.decodeIfPresent(String.self, forKey: .bodyPart) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Strength"
        barType = try container.decodeIfPresent(BarType.self, forKey: .barType)
        plannedSets = try container.decodeIfPresent([SnapshotSet].self, forKey: .plannedSets) ?? []
        previousSets = try container.decodeIfPresent([LiveSet].self, forKey: .previousSets) ?? []
    }

    /// The best of the previous sets, "185 × 8", or nil when there is no history.
    var lastSummary: String? {
        let best = previousSets
            .filter { !$0.isEmpty }
            .max { lhs, rhs in
                if lhs.weight != rhs.weight { return (lhs.weight ?? 0) < (rhs.weight ?? 0) }
                return (lhs.reps ?? 0) < (rhs.reps ?? 0)
            }
        guard let best else { return nil }
        return Formatting.compactSetSummary(weight: best.weight, reps: best.reps, time: best.time)
    }
}

/// A planned set: what the template says to do.
struct SnapshotSet: Codable, Equatable, Sendable {
    var reps: Int?
    var weight: Double?

    init(reps: Int? = nil, weight: Double? = nil) {
        self.reps = reps
        self.weight = weight
    }
}

extension LiveWorkout {
    /// A live workout from a snapshot template, the way the phone starts one from a
    /// `WorkoutTemplate`: planned sets become sets (one empty set when a template has none), the
    /// previous performance rides along, and every exercise and set gets a fresh id.
    init(from template: SnapshotTemplate, at start: Date = Date(), restSeconds: TimeInterval) {
        let exercises = template.exercises.map { planned -> LiveExercise in
            let sets = planned.plannedSets.isEmpty
                ? [LiveSet()]
                : planned.plannedSets.map { LiveSet(reps: $0.reps, weight: $0.weight) }
            return LiveExercise(
                name: planned.name,
                bodyPart: planned.bodyPart,
                category: planned.category,
                barType: planned.barType,
                sets: sets,
                previousSets: planned.previousSets
            )
        }
        self.init(title: template.name, startedAt: start, templateName: template.name, exercises: exercises, restSeconds: restSeconds)
    }
}
