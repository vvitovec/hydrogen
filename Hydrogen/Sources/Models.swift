import Foundation
import SwiftUI
import UIKit

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
    var appearance = AppAppearance.system

    init(
        isAdBlockEnabled: Bool = true,
        searchEngine: SearchEngine = .duckDuckGo,
        appearance: AppAppearance = .system
    ) {
        self.isAdBlockEnabled = isAdBlockEnabled
        self.searchEngine = searchEngine
        self.appearance = appearance
    }

    private enum CodingKeys: String, CodingKey {
        case isAdBlockEnabled
        case searchEngine
        case appearance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isAdBlockEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAdBlockEnabled) ?? true
        searchEngine = try container.decodeIfPresent(SearchEngine.self, forKey: .searchEngine) ?? .duckDuckGo
        appearance = try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isAdBlockEnabled, forKey: .isAdBlockEnabled)
        try container.encode(searchEngine, forKey: .searchEngine)
        try container.encode(appearance, forKey: .appearance)
    }
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

enum AppAppearance: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

enum HydrogenTheme {
    static let background = adaptive(light: rgb(0.958, 0.973, 0.992), dark: rgb(0.055, 0.064, 0.075))
    static let surface = adaptive(light: rgb(0.978, 0.986, 0.996), dark: rgb(0.078, 0.089, 0.103))
    static let elevatedSurface = adaptive(light: rgb(0.992, 0.996, 1.0), dark: rgb(0.105, 0.118, 0.137))
    static let ink = adaptive(light: rgb(0.065, 0.095, 0.15), dark: rgb(0.925, 0.945, 0.965))
    static let mutedInk = adaptive(light: rgb(0.34, 0.40, 0.48), dark: rgb(0.67, 0.71, 0.76))
    static let faintInk = adaptive(light: rgb(0.58, 0.65, 0.73), dark: rgb(0.45, 0.50, 0.56))
    static let hairline = adaptive(light: rgb(0.73, 0.80, 0.88), dark: rgb(0.22, 0.26, 0.31))
    static let helium = adaptive(light: rgb(0.18, 0.44, 0.74), dark: rgb(0.45, 0.68, 0.94))
    static let privateTint = adaptive(light: rgb(0.39, 0.38, 0.68), dark: rgb(0.62, 0.58, 0.93))
    static let warning = adaptive(light: rgb(0.76, 0.42, 0.18), dark: rgb(0.93, 0.64, 0.38))

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}
