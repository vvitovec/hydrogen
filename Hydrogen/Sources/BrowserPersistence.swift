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

        pendingTask = Task { [weak self, persistence, snapshot, delayNanoseconds] in
            if delayNanoseconds > 0 {
                do {
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }
            await Task.detached(priority: .utility) {
                persistence.save(snapshot)
            }.value

            await MainActor.run {
                guard !Task.isCancelled, let self else { return }
                if self.latestSnapshot == snapshot {
                    self.latestSnapshot = nil
                }
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
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.timeIntervalSinceReferenceDate.bitPattern)
        }
        return encoder
    }
}

extension JSONDecoder {
    static var hydrogen: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let bitPattern = try? container.decode(UInt64.self) {
                return Date(timeIntervalSinceReferenceDate: Double(bitPattern: bitPattern))
            }
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }

            let value = try container.decode(String.self)
            if let date = DateCodingFormatter.date(from: value, options: [.withInternetDateTime, .withFractionalSeconds]) {
                return date
            }
            if let date = DateCodingFormatter.date(from: value, options: [.withInternetDateTime]) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return decoder
    }
}

private enum DateCodingFormatter {
    static func date(from value: String, options: ISO8601DateFormatter.Options) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = options
        return formatter.date(from: value)
    }
}
