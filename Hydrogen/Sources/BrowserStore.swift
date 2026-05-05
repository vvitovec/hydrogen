import Foundation
import SwiftUI
import WebKit

@MainActor
final class BrowserStore: ObservableObject {
    private static let historyLimit = 500

    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published var bookmarks: [BookmarkItem] = []
    @Published var history: [HistoryItem] = []
    @Published var settings: BrowserSettings
    @Published var libraryMode: LibraryMode = .bookmarks

    let adBlocker = AdBlocker()
    private let persistence: BrowserPersistence
    private let snapshotWriter: DebouncedSnapshotWriter
    private let inactiveTabSuspensionDelay: TimeInterval
    private var cachedStartPageHTML: String?
    private var tabSuspensionTask: Task<Void, Never>?

    var activeTab: BrowserTab? {
        tabs.first { $0.id == activeTabID }
    }

    init(
        persistence: BrowserPersistence = BrowserPersistence(),
        saveDelay: TimeInterval = 0.35,
        inactiveTabSuspensionDelay: TimeInterval = 30
    ) {
        self.persistence = persistence
        self.snapshotWriter = DebouncedSnapshotWriter(persistence: persistence, delay: saveDelay)
        self.inactiveTabSuspensionDelay = inactiveTabSuspensionDelay

        let snapshot = persistence.load()
        bookmarks = snapshot.bookmarks
        history = snapshot.history
        settings = snapshot.settings
        adBlocker.isEnabled = snapshot.settings.isAdBlockEnabled
        adBlocker.prepare()
        newTab(isPrivate: false)
    }

    deinit {
        tabSuspensionTask?.cancel()
    }

    func newTab(isPrivate: Bool, request: URLRequest? = nil) {
        let tab = BrowserTab(isPrivate: isPrivate) { [weak self] webView in
            self?.adBlocker.apply(to: webView)
        }
        configure(tab)
        tabs.append(tab)
        activeTabID = tab.id

        if let request {
            tab.load(request)
        } else {
            tab.reset(startPageHTML: startPageHTML())
        }
        scheduleInactiveTabSuspension()
    }

    func closeTab(_ tab: BrowserTab) {
        guard tabs.count > 1 else {
            tab.tearDown()
            tabs.removeAll { $0.id == tab.id }
            newTab(isPrivate: false)
            return
        }

        let wasActive = tab.id == activeTabID
        tab.tearDown()
        tabs.removeAll { $0.id == tab.id }
        if wasActive {
            activeTabID = tabs.last?.id
            activeTab?.restore(startPageHTML: startPageHTML())
        }
        scheduleInactiveTabSuspension()
    }

    func selectTab(_ tab: BrowserTab) {
        guard tabs.contains(where: { $0.id == tab.id }) else { return }
        tab.restore(startPageHTML: startPageHTML())
        activeTabID = tab.id
        scheduleInactiveTabSuspension()
    }

    func loadInput(_ input: String) {
        let request = URLRequest(url: URLNormalizer.url(for: input, searchEngine: settings.searchEngine))
        if let tab = activeTab {
            tab.load(request)
        } else {
            newTab(isPrivate: false, request: request)
        }
    }

    func open(_ url: URL, inNewTab: Bool = false, isPrivate: Bool? = nil) {
        let request = URLRequest(url: url)
        if inNewTab || activeTab == nil {
            newTab(isPrivate: isPrivate ?? activeTab?.isPrivate ?? false, request: request)
        } else {
            activeTab?.load(request)
            scheduleInactiveTabSuspension()
        }
    }

    func openExternalURL(_ url: URL) {
        guard URLNormalizer.isWebURL(url) else { return }
        open(url)
    }

    func addOrRemoveBookmark(for tab: BrowserTab) {
        guard let url = tab.url else { return }
        if let index = bookmarks.firstIndex(where: { $0.url == url }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.insert(BookmarkItem(title: tab.displayTitle, url: url), at: 0)
        }
        invalidateStartPageHTML()
        save()
    }

    func isBookmarked(_ tab: BrowserTab) -> Bool {
        guard let url = tab.url else { return false }
        return bookmarks.contains { $0.url == url }
    }

    func deleteBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        invalidateStartPageHTML()
        save()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        invalidateStartPageHTML()
        save()
    }

    func clearHistory() {
        history.removeAll()
        invalidateStartPageHTML()
        save()
    }

    func setAdBlockEnabled(_ isEnabled: Bool) {
        settings.isAdBlockEnabled = isEnabled
        adBlocker.isEnabled = isEnabled
        adBlocker.prepare()
        loadedWebViews.forEach { webView in
            adBlocker.apply(to: webView)
        }
        activeTab?.reload()
        save()
    }

    func shareItems() -> [Any] {
        guard let url = activeTab?.url else { return [] }
        return [url]
    }

    func flushPendingSave() {
        snapshotWriter.flush()
    }

    func handleMemoryPressure() {
        suspendInactiveTabs()
    }

    func prepareForBackground() {
        flushPendingSave()
        suspendInactiveTabs()
    }

    private func configure(_ tab: BrowserTab) {
        tab.onVisited = { [weak self, weak tab] title, url in
            guard let self, let tab, !tab.isPrivate else { return }
            self.recordVisit(title: title, url: url)
        }

        tab.onOpenNewTab = { [weak self, weak tab] request in
            guard let self else { return }
            self.newTab(isPrivate: tab?.isPrivate ?? false, request: request)
        }

        tab.onOpenExternal = { url in
            UIApplication.shared.open(url)
        }
    }

    func recordVisit(title: String, url: URL) {
        guard URLNormalizer.isWebURL(url) else { return }
        if let first = history.first, first.url == url, first.title == title {
            return
        }

        history.removeAll { $0.url == url }
        history.insert(HistoryItem(title: title, url: url, visitedAt: .now), at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
        invalidateStartPageHTML()
        save()
    }

    private func save() {
        snapshotWriter.schedule(snapshot())
    }

    private func snapshot() -> BrowserSnapshot {
        BrowserSnapshot(bookmarks: bookmarks, history: history, settings: settings)
    }

    private func startPageHTML() -> String {
        if let cachedStartPageHTML {
            return cachedStartPageHTML
        }

        let html = StartPage.html(bookmarks: bookmarks, history: history)
        cachedStartPageHTML = html
        return html
    }

    private var loadedWebViews: [WKWebView] {
        tabs.compactMap(\.webView)
    }

    private func invalidateStartPageHTML() {
        cachedStartPageHTML = nil
    }

    private func scheduleInactiveTabSuspension() {
        tabSuspensionTask?.cancel()
        let delay = UInt64(max(0, inactiveTabSuspensionDelay) * 1_000_000_000)
        tabSuspensionTask = Task { [weak self, delay] in
            if delay > 0 {
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, !Task.isCancelled else { return }
                self.suspendInactiveTabs()
            }
        }
    }

    private func suspendInactiveTabs() {
        guard let activeTabID else { return }
        tabs.forEach { tab in
            guard tab.id != activeTabID else { return }
            tab.suspend()
        }
    }
}

enum LibraryMode: String, CaseIterable, Identifiable {
    case bookmarks = "Bookmarks"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }
}
