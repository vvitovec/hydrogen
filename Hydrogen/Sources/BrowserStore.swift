import Foundation
import SwiftUI
import WebKit

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab] = []
    @Published var activeTabID: UUID?
    @Published var bookmarks: [BookmarkItem] = []
    @Published var history: [HistoryItem] = []
    @Published var settings: BrowserSettings
    @Published var libraryMode: LibraryMode = .bookmarks

    let adBlocker = AdBlocker()
    private let persistence = BrowserPersistence()

    var activeTab: BrowserTab? {
        tabs.first { $0.id == activeTabID }
    }

    init() {
        let snapshot = persistence.load()
        bookmarks = snapshot.bookmarks
        history = snapshot.history
        settings = snapshot.settings
        adBlocker.isEnabled = snapshot.settings.isAdBlockEnabled
        newTab(isPrivate: false)
    }

    func newTab(isPrivate: Bool, request: URLRequest? = nil) {
        let tab = BrowserTab(isPrivate: isPrivate)
        configure(tab)
        tabs.append(tab)
        activeTabID = tab.id
        adBlocker.apply(to: tab.webView)

        if let request {
            tab.load(request)
        }
    }

    func closeTab(_ tab: BrowserTab) {
        guard tabs.count > 1 else {
            tab.reset()
            return
        }

        let wasActive = tab.id == activeTabID
        tabs.removeAll { $0.id == tab.id }
        if wasActive {
            activeTabID = tabs.last?.id
        }
    }

    func selectTab(_ tab: BrowserTab) {
        activeTabID = tab.id
    }

    func loadInput(_ input: String) {
        let request = URLRequest(url: URLNormalizer.url(for: input))
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
        save()
    }

    func isBookmarked(_ tab: BrowserTab) -> Bool {
        guard let url = tab.url else { return false }
        return bookmarks.contains { $0.url == url }
    }

    func deleteBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        save()
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        save()
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    func setAdBlockEnabled(_ isEnabled: Bool) {
        settings.isAdBlockEnabled = isEnabled
        adBlocker.isEnabled = isEnabled
        tabs.forEach { tab in
            adBlocker.apply(to: tab.webView)
            tab.reload()
        }
        save()
    }

    func shareItems() -> [Any] {
        guard let url = activeTab?.url else { return [] }
        return [url]
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

    private func recordVisit(title: String, url: URL) {
        guard URLNormalizer.isWebURL(url) else { return }
        history.removeAll { $0.url == url }
        history.insert(HistoryItem(title: title, url: url, visitedAt: .now), at: 0)
        if history.count > 500 {
            history.removeLast(history.count - 500)
        }
        save()
    }

    private func save() {
        persistence.save(BrowserSnapshot(bookmarks: bookmarks, history: history, settings: settings))
    }
}

enum LibraryMode: String, CaseIterable, Identifiable {
    case bookmarks = "Bookmarks"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }
}
