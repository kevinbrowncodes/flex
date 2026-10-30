import Foundation

/// Keeps the workout in progress on disk as JSON, so a closed app resumes where it left off
/// (STORY_002). One file per device, in Application Support; the phone and the watch each keep
/// their own.
struct LiveWorkoutStore {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    /// `Application Support/live-workout.json`, creating the folder when it is missing.
    static func `default`(fileManager: FileManager = .default) -> LiveWorkoutStore {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        try? fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        return LiveWorkoutStore(url: support.appendingPathComponent("live-workout.json"))
    }

    // Dates stay as Foundation keeps them (seconds since 2001, a Double), so a workout decodes to
    // exactly the value that was saved; shifting the epoch for the file would round the last bits.
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }()

    /// The saved workout, or nil when there is none or the file will not decode (then it is removed).
    func load() -> LiveWorkout? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let workout = try? Self.decoder.decode(LiveWorkout.self, from: data) else {
            clear()
            return nil
        }
        return workout
    }

    func save(_ workout: LiveWorkout) throws {
        let data = try Self.encoder.encode(workout)
        try data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
