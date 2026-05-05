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
    static let background = Color(red: 0.958, green: 0.973, blue: 0.992)
    static let surface = Color(red: 0.978, green: 0.986, blue: 0.996)
    static let elevatedSurface = Color(red: 0.992, green: 0.996, blue: 1.0)
    static let ink = Color(red: 0.065, green: 0.095, blue: 0.15)
    static let mutedInk = Color(red: 0.34, green: 0.40, blue: 0.48)
    static let faintInk = Color(red: 0.58, green: 0.65, blue: 0.73)
    static let hairline = Color(red: 0.73, green: 0.80, blue: 0.88)
    static let helium = Color(red: 0.18, green: 0.44, blue: 0.74)
    static let privateTint = Color(red: 0.39, green: 0.38, blue: 0.68)
    static let warning = Color(red: 0.76, green: 0.42, blue: 0.18)
}
