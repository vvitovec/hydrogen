import Foundation

final class BrowserPersistence {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = directory.appending(path: "BrowserSnapshot.json")
        }
    }

    func load() -> BrowserSnapshot {
        guard let data = try? Data(contentsOf: fileURL) else {
            return BrowserSnapshot()
        }

        do {
            return try JSONDecoder.hydrogen.decode(BrowserSnapshot.self, from: data)
        } catch {
            return BrowserSnapshot()
        }
    }

    func save(_ snapshot: BrowserSnapshot) {
        do {
            let data = try JSONEncoder.hydrogen.encode(snapshot)
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save browser snapshot: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class DebouncedSnapshotWriter {
    private let persistence: BrowserPersistence
    private let delayNanoseconds: UInt64
    private var pendingTask: Task<Void, Never>?
    private var latestSnapshot: BrowserSnapshot?

    init(persistence: BrowserPersistence, delay: TimeInterval = 0.35) {
        self.persistence = persistence
        self.delayNanoseconds = UInt64(max(0, delay) * 1_000_000_000)
    }

    func schedule(_ snapshot: BrowserSnapshot) {
        latestSnapshot = snapshot
        pendingTask?.cancel()

        pendingTask = Task { @MainActor [weak self, snapshot, delayNanoseconds] in
            if delayNanoseconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled, let self else { return }
            self.persistence.save(snapshot)
            if self.latestSnapshot == snapshot {
                self.latestSnapshot = nil
            }
        }
    }

    func flush() {
        pendingTask?.cancel()
        pendingTask = nil

        guard let latestSnapshot else { return }
        persistence.save(latestSnapshot)
        self.latestSnapshot = nil
    }

    deinit {
        pendingTask?.cancel()
    }
}

extension JSONEncoder {
    static var hydrogen: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var hydrogen: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
