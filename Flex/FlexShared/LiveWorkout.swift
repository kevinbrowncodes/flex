import Foundation

/// A workout in progress: the one value the phone and the watch both hold while sets are being
/// logged. Nothing here is a SwiftData model; `LiveWorkoutBridge` (phone only) turns a finished
/// one into a saved `Workout`. Every change is a `LiveWorkoutEdit` so the same step can be taken
/// by a tap, a Digital Crown turn, Siri, or an edit arriving from the other device (STORY_002).
struct LiveWorkout: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var title: String
    var startedAt: Date
    /// The template this workout was started from, if any.
    var templateName: String?
    var exercises: [LiveExercise]
    /// Rest after each completed set, in seconds; 0 is off. Copied from Settings when the workout
    /// starts, so the watch rests the same way the phone does (STORY_003).
    var restSeconds: TimeInterval
    /// The rest running now, if any. It stays until skipped or replaced; `restRemaining(at:)` says
    /// whether it is still counting.
    var rest: LiveRest?
    /// When the last edit was applied.
    var updatedAt: Date

    init(id: UUID = UUID(), title: String? = nil, startedAt: Date = Date(), templateName: String? = nil, exercises: [LiveExercise] = [], restSeconds: TimeInterval = 0) {
        self.id = id
        self.title = title ?? LiveWorkout.defaultTitle(for: startedAt)
        self.startedAt = startedAt
        self.templateName = templateName
        self.exercises = exercises
        self.restSeconds = max(0, restSeconds)
        self.updatedAt = startedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, startedAt, templateName, exercises, restSeconds, rest, updatedAt
    }

    /// Tolerant of older or smaller JSON: a missing list is empty, a missing time is the start.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? LiveWorkout.defaultTitle(for: startedAt)
        templateName = try container.decodeIfPresent(String.self, forKey: .templateName)
        exercises = try container.decodeIfPresent([LiveExercise].self, forKey: .exercises) ?? []
        restSeconds = max(0, try container.decodeIfPresent(TimeInterval.self, forKey: .restSeconds) ?? 0)
        rest = try container.decodeIfPresent(LiveRest.self, forKey: .rest)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? startedAt
    }

    /// "Morning Workout", "Afternoon Workout" or "Evening Workout" depending on the start time.
    static func defaultTitle(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 4..<12: return "Morning Workout"
        case 12..<17: return "Afternoon Workout"
        default: return "Evening Workout"
        }
    }

    // MARK: - Reading

    var allSets: [LiveSet] { exercises.flatMap { $0.sets } }

    /// Total volume so far: weight × reps, summed over every set.
    var totalVolume: Double { allSets.reduce(0) { $0 + $1.volume } }

    /// Sets with something logged in them.
    var loggedSetCount: Int { allSets.filter { !$0.isEmpty }.count }

    var completedSetCount: Int { allSets.filter { $0.isCompleted }.count }

    var hasEmptySets: Bool { allSets.contains { $0.isEmpty } }

    func exercise(withID id: UUID) -> LiveExercise? {
        exercises.first { $0.id == id }
    }

    func set(withID id: UUID) -> LiveSet? {
        for exercise in exercises {
            if let set = exercise.sets.first(where: { $0.id == id }) { return set }
        }
        return nil
    }

    /// The exercise that holds the set, if any.
    func exercise(containingSet setID: UUID) -> LiveExercise? {
        exercises.first { $0.sets.contains { $0.id == setID } }
    }

    /// Seconds of rest left at `date`; nil when none is running or it has ended.
    func restRemaining(at date: Date) -> TimeInterval? {
        rest?.remaining(at: date)
    }

    // MARK: - Editing

    /// Applies one edit. An edit naming an id this workout does not hold does nothing; adding an
    /// exercise or a set already present does nothing, so a duplicate or late edit is harmless.
    mutating func apply(_ edit: LiveWorkoutEdit, at date: Date = Date()) {
        switch edit {
        case .rename(let title):
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            self.title = trimmed
        case .addExercise(let exercise):
            guard self.exercise(withID: exercise.id) == nil else { return }
            exercises.append(exercise)
        case .removeExercise(let exerciseID):
            guard self.exercise(withID: exerciseID) != nil else { return }
            exercises.removeAll { $0.id == exerciseID }
        case .addSet(let exerciseID, let set):
            guard let index = exercises.firstIndex(where: { $0.id == exerciseID }),
                  self.set(withID: set.id) == nil else { return }
            exercises[index].sets.append(set)
        case .deleteSet(let exerciseID, let setID):
            guard let index = exercises.firstIndex(where: { $0.id == exerciseID }),
                  exercises[index].sets.contains(where: { $0.id == setID }) else { return }
            exercises[index].sets.removeAll { $0.id == setID }
        case .setWeight(let setID, let weight):
            guard update(setID, { $0.weight = weight }) else { return }
        case .setReps(let setID, let reps):
            guard update(setID, { $0.reps = reps }) else { return }
        case .setTime(let setID, let time):
            guard update(setID, { $0.time = (time ?? "").isEmpty ? nil : time }) else { return }
        case .setCompleted(let setID, let isCompleted):
            guard update(setID, { $0.isCompleted = isCompleted }) else { return }
            // Ticking a set starts rest (replacing one running); unticking the set that started it cancels.
            if isCompleted {
                if restSeconds > 0 {
                    rest = LiveRest(startedAt: date, endsAt: date.addingTimeInterval(restSeconds), setID: setID)
                }
            } else if rest?.setID == setID {
                rest = nil
            }
        case .setRestSeconds(let seconds):
            restSeconds = max(0, seconds)
        case .adjustRest(let delta):
            guard var running = rest, running.remaining(at: date) != nil else { return }
            running.endsAt = max(date, running.endsAt.addingTimeInterval(delta))
            rest = running
        case .skipRest:
            guard rest != nil else { return }
            rest = nil
        }
        updatedAt = date
    }

    func applying(_ edit: LiveWorkoutEdit, at date: Date = Date()) -> LiveWorkout {
        var copy = self
        copy.apply(edit, at: date)
        return copy
    }

    /// Changes one set in place; false when no exercise holds it.
    private mutating func update(_ setID: UUID, _ change: (inout LiveSet) -> Void) -> Bool {
        for exerciseIndex in exercises.indices {
            if let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) {
                change(&exercises[exerciseIndex].sets[setIndex])
                return true
            }
        }
        return false
    }

    // MARK: - Finishing

    /// The workout as it is saved: empty sets dropped, exercises with nothing logged dropped.
    func finished(at end: Date) -> FinishedWorkout {
        var trimmed = self
        trimmed.exercises = exercises.compactMap { exercise in
            var kept = exercise
            kept.sets = exercise.sets.filter { !$0.isEmpty }
            return kept.sets.isEmpty ? nil : kept
        }
        trimmed.rest = nil
        trimmed.updatedAt = end
        return FinishedWorkout(workout: trimmed, endedAt: end)
    }
}

/// The rest countdown after a set, as wall-clock times, so a relaunched app and both devices agree
/// on what is left (STORY_003).
struct LiveRest: Codable, Equatable, Sendable {
    var startedAt: Date
    var endsAt: Date
    /// The set whose completion started this rest, when one did.
    var setID: UUID?

    /// Seconds left at `date`; nil once it has ended.
    func remaining(at date: Date) -> TimeInterval? {
        let left = endsAt.timeIntervalSince(date)
        return left > 0 ? left : nil
    }
}

/// One exercise in a live workout. Identity across devices is `name` (see `ExerciseName`).
struct LiveExercise: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var bodyPart: String
    var category: String
    var barType: BarType?
    var sets: [LiveSet]
    /// The most recent earlier performance of this exercise, in set order: the "Previous" column
    /// and what a new set is pre-filled from. Filled by the phone, which holds the history.
    var previousSets: [LiveSet]

    init(id: UUID = UUID(), name: String, bodyPart: String, category: String = "Strength", barType: BarType? = nil, sets: [LiveSet] = [], previousSets: [LiveSet] = []) {
        self.id = id
        self.name = name
        self.bodyPart = bodyPart
        self.category = category
        self.barType = barType
        self.sets = sets
        self.previousSets = previousSets
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, bodyPart, category, barType, sets, previousSets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        bodyPart = try container.decodeIfPresent(String.self, forKey: .bodyPart) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Strength"
        barType = try container.decodeIfPresent(BarType.self, forKey: .barType)
        sets = try container.decodeIfPresent([LiveSet].self, forKey: .sets) ?? []
        previousSets = try container.decodeIfPresent([LiveSet].self, forKey: .previousSets) ?? []
    }

    var isCardio: Bool { bodyPart == "Cardio" }

    /// Whether this exercise is loaded on a barbell (shows the plate calculator).
    var usesBarbell: Bool {
        barType != nil || name.localizedCaseInsensitiveContains("(Barbell)")
    }

    /// Sets with something logged in them.
    var loggedSets: [LiveSet] { sets.filter { !$0.isEmpty } }

    /// The heaviest weight logged in any set, if any.
    var bestWeight: Double? { sets.compactMap { $0.weight }.max() }

    /// The previous workout's set at the same position, for the "Previous" column.
    func previousSet(at index: Int) -> LiveSet? {
        index < previousSets.count ? previousSets[index] : nil
    }

    /// The set to log next: the first not yet completed, or the last one when every set is done.
    var currentSetIndex: Int? {
        sets.firstIndex { !$0.isCompleted } ?? (sets.isEmpty ? nil : sets.count - 1)
    }

    var allSetsCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }
}

/// One set in a live workout. Its number is its position in the exercise's `sets`.
struct LiveSet: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var reps: Int?
    var weight: Double?
    var time: String?
    var distance: Double?
    var isCompleted: Bool

    init(id: UUID = UUID(), reps: Int? = nil, weight: Double? = nil, time: String? = nil, distance: Double? = nil, isCompleted: Bool = false) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.time = time
        self.distance = distance
        self.isCompleted = isCompleted
    }

    private enum CodingKeys: String, CodingKey {
        case id, reps, weight, time, distance, isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }

    /// True when nothing has been logged for this set.
    var isEmpty: Bool {
        weight == nil && reps == nil && (time ?? "").isEmpty && distance == nil
    }

    /// Volume for this set: weight × reps. A set with a weight but no reps counts the weight once.
    var volume: Double {
        guard let weight, weight > 0 else { return 0 }
        return weight * Double(max(reps ?? 1, 0))
    }
}

/// One change to a live workout. Set edits name the set alone: a set id is unique in a workout.
enum LiveWorkoutEdit: Codable, Equatable, Sendable {
    case rename(String)
    case addExercise(LiveExercise)
    case removeExercise(exerciseID: UUID)
    case addSet(exerciseID: UUID, set: LiveSet)
    case deleteSet(exerciseID: UUID, setID: UUID)
    case setWeight(setID: UUID, weight: Double?)
    case setReps(setID: UUID, reps: Int?)
    case setTime(setID: UUID, time: String?)
    case setCompleted(setID: UUID, isCompleted: Bool)
    /// The rest default for the rest of this workout (0 is off).
    case setRestSeconds(TimeInterval)
    /// Moves the running rest's end, never earlier than the edit itself; nothing when none is running.
    case adjustRest(by: TimeInterval)
    case skipRest
}

/// A live workout that has been finished: what the phone saves, and what a watch sends it.
struct FinishedWorkout: Codable, Equatable, Sendable {
    var workout: LiveWorkout
    var endedAt: Date

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(workout.startedAt))
    }
}
