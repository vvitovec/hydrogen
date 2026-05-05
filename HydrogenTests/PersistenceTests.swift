import XCTest
@testable import Hydrogen

final class PersistenceTests: XCTestCase {
    func testSnapshotRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "BrowserSnapshot.json")
        let persistence = BrowserPersistence(fileURL: url)
        let snapshot = BrowserSnapshot(
            bookmarks: [BookmarkItem(title: "Example", url: URL(string: "https://example.com")!)],
            history: [HistoryItem(title: "Duck", url: URL(string: "https://duckduckgo.com")!, visitedAt: Date(timeIntervalSince1970: 10))],
            settings: BrowserSettings(isAdBlockEnabled: false)
        )

        persistence.save(snapshot)

        XCTAssertEqual(persistence.load(), snapshot)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
