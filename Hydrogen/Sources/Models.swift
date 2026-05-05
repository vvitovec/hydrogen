import Foundation
import SwiftUI

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

enum HydrogenTheme {
    static let background = Color(red: 0.965, green: 0.957, blue: 0.93)
    static let surface = Color(red: 0.985, green: 0.98, blue: 0.958)
    static let elevatedSurface = Color(red: 0.998, green: 0.992, blue: 0.97)
    static let ink = Color(red: 0.10, green: 0.105, blue: 0.09)
    static let mutedInk = Color(red: 0.39, green: 0.41, blue: 0.35)
    static let faintInk = Color(red: 0.62, green: 0.63, blue: 0.56)
    static let hairline = Color(red: 0.82, green: 0.82, blue: 0.74)
    static let helium = Color(red: 0.54, green: 0.64, blue: 0.34)
    static let privateTint = Color(red: 0.46, green: 0.35, blue: 0.64)
    static let warning = Color(red: 0.78, green: 0.47, blue: 0.18)
}
