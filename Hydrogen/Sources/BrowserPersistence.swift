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
