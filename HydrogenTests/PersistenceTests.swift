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

    @MainActor
    func testClosingLastTabCreatesFreshRegularTab() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "BrowserSnapshot.json")
        let persistence = BrowserPersistence(fileURL: url)
        let store = BrowserStore(persistence: persistence, saveDelay: 60)

        guard let originalTab = store.activeTab else {
            XCTFail("Expected an initial tab")
            return
        }

        store.closeTab(originalTab)

        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertNotEqual(store.activeTab?.id, originalTab.id)
        XCTAssertEqual(store.activeTab?.isPrivate, false)
        XCTAssertNil(store.activeTab?.url)
        XCTAssertNil(store.activeTab?.webView)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @MainActor
    func testMemoryPressureSuspendsInactiveTabsAndRestoresOnSelection() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "BrowserSnapshot.json")
        let persistence = BrowserPersistence(fileURL: url)
        let store = BrowserStore(persistence: persistence, saveDelay: 60, inactiveTabSuspensionDelay: 60)

        guard let firstTab = store.activeTab else {
            XCTFail("Expected an initial tab")
            return
        }

        store.open(URL(string: "https://example.com")!, inNewTab: false)
        store.newTab(isPrivate: false)
        guard let secondTab = store.activeTab else {
            XCTFail("Expected a second tab")
            return
        }

        XCTAssertNotNil(firstTab.webView)
        XCTAssertNil(secondTab.webView)

        store.handleMemoryPressure()

        XCTAssertNil(firstTab.webView)
        XCTAssertTrue(firstTab.isSuspended)
        XCTAssertNil(secondTab.webView)
        XCTAssertFalse(secondTab.isSuspended)

        store.selectTab(firstTab)

        XCTAssertEqual(store.activeTabID, firstTab.id)
        XCTAssertNotNil(firstTab.webView)
        XCTAssertFalse(firstTab.isSuspended)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
