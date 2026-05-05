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

    @MainActor
    func testDebouncedSnapshotWriterCoalescesPendingSaves() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "BrowserSnapshot.json")
        let persistence = BrowserPersistence(fileURL: url)
        let writer = DebouncedSnapshotWriter(persistence: persistence, delay: 60)
        let first = BrowserSnapshot(
            bookmarks: [BookmarkItem(title: "First", url: URL(string: "https://first.example")!)],
            history: [],
            settings: BrowserSettings(isAdBlockEnabled: true)
        )
        let second = BrowserSnapshot(
            bookmarks: [BookmarkItem(title: "Second", url: URL(string: "https://second.example")!)],
            history: [],
            settings: BrowserSettings(isAdBlockEnabled: false)
        )

        writer.schedule(first)
        writer.schedule(second)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        writer.flush()
        XCTAssertEqual(persistence.load(), second)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @MainActor
    func testBrowserStoreSkipsConsecutiveDuplicateHistoryVisit() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "BrowserSnapshot.json")
        let persistence = BrowserPersistence(fileURL: url)
        let store = BrowserStore(persistence: persistence, saveDelay: 60)
        let visitURL = URL(string: "https://example.com")!

        store.recordVisit(title: "Example", url: visitURL)
        store.recordVisit(title: "Example", url: visitURL)
        store.flushPendingSave()

        XCTAssertEqual(store.history.count, 1)
        XCTAssertEqual(persistence.load().history.count, 1)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
