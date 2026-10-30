import Foundation

/// The one JSON shape Flex writes to disk and sends between devices (STORY_002, STORY_005).
/// Dates stay as Foundation keeps them (seconds since 2001, a Double), so a value decodes to
/// exactly what was encoded; shifting the epoch for the file would round the last bits.
enum FlexJSON {
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
}

/// One `Codable` value kept as a JSON file, for state that must outlive the process (STORY_005).
/// A file that will not decode counts as no value and is removed.
struct JSONFileStore<Value: Codable> {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    /// `Application Support/<name>`, creating the folder when it is missing.
    static func `default`(named name: String, fileManager: FileManager = .default) -> JSONFileStore {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        try? fileManager.createDirectory(at: support, withIntermediateDirectories: true)
        return JSONFileStore(url: support.appendingPathComponent(name))
    }

    func load() -> Value? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let value = try? FlexJSON.decoder.decode(Value.self, from: data) else {
            clear()
            return nil
        }
        return value
    }

    func save(_ value: Value) throws {
        let data = try FlexJSON.encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
