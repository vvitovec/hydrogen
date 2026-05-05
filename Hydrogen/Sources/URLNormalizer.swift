import Foundation

enum URLNormalizer {
    static func url(for input: String, searchEngine: SearchEngine = .duckDuckGo) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return searchEngine.searchURL(for: "")
        }

        if let url = URL(string: trimmed), isWebURL(url), url.host() != nil {
            return url
        }

        if looksLikeDomain(trimmed), let url = URL(string: "https://\(trimmed)") {
            return url
        }

        return searchEngine.searchURL(for: trimmed)
    }

    static func isWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    static func isInternalStartURL(_ url: URL) -> Bool {
        url.scheme == "about" || url.absoluteString == "about:blank"
    }

    private static func looksLikeDomain(_ input: String) -> Bool {
        guard !input.contains(" "), input.contains(".") else { return false }
        guard input.range(of: #"^[A-Za-z0-9.-]+\.[A-Za-z]{2,}(:[0-9]+)?(/.*)?$"#, options: .regularExpression) != nil else {
            return false
        }
        return true
    }
}
