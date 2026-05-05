import Foundation

struct BookmarkItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var url: URL
    var createdAt = Date()
}

struct HistoryItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var url: URL
    var visitedAt: Date
}

struct BrowserSettings: Codable, Equatable {
    var isAdBlockEnabled = true
    var searchEngine = SearchEngine.duckDuckGo
}

struct BrowserSnapshot: Codable, Equatable {
    var bookmarks: [BookmarkItem] = []
    var history: [HistoryItem] = []
    var settings = BrowserSettings()
}

enum SearchEngine: String, Codable, CaseIterable, Identifiable {
    case duckDuckGo

    var id: String { rawValue }

    func searchURL(for query: String) -> URL {
        var components = URLComponents(string: "https://duckduckgo.com/")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url!
    }
}
