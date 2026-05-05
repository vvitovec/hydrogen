import Foundation

enum StartPage {
    static func html(bookmarks: [BookmarkItem] = [], history: [HistoryItem] = []) -> String {
        let bookmarkedURLs = Set(bookmarks.map(\.url))
        let bookmarkLinks = bookmarks.prefix(4).map {
            Link(title: $0.title, subtitle: $0.url.host(percentEncoded: false) ?? $0.url.absoluteString, url: $0.url, icon: "star")
        }
        let recentLinks = history
            .filter { !bookmarkedURLs.contains($0.url) }
            .prefix(4)
            .map { Link(title: $0.title, subtitle: $0.url.host(percentEncoded: false) ?? $0.url.absoluteString, url: $0.url, icon: "clock") }

        return """
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          html, body {
            margin: 0;
            min-height: 100%;
            font: -apple-system-body;
            background: #f5f8fc;
            color: #101826;
            -webkit-font-smoothing: antialiased;
          }
          main {
            min-height: 100%;
            display: flex;
            align-items: flex-start;
            justify-content: center;
            padding: 62px 22px 118px;
            box-sizing: border-box;
          }
          section.shell {
            width: min(100%, 560px);
          }
          h1 {
            font-size: 36px;
            line-height: 1;
            font-weight: 720;
            margin: 0;
            letter-spacing: 0;
          }
          .quick {
            display: grid;
            gap: 30px;
            margin-top: 46px;
          }
          h2 {
            margin: 0 0 10px;
            font-size: 12px;
            line-height: 1;
            color: #728197;
            font-weight: 650;
            letter-spacing: .04em;
            text-transform: uppercase;
          }
          .links {
            display: grid;
            gap: 0;
          }
          a {
            display: grid;
            grid-template-columns: 28px minmax(0, 1fr);
            gap: 12px;
            align-items: center;
            min-height: 46px;
            padding: 10px 0;
            color: inherit;
            text-decoration: none;
            border-top: 1px solid rgba(180, 197, 218, .45);
            box-sizing: border-box;
          }
          a:last-child {
            border-bottom: 1px solid rgba(180, 197, 218, .45);
          }
          .glyph {
            display: grid;
            place-items: center;
            width: 28px;
            height: 28px;
            color: #2f6fbd;
            font-size: 13px;
          }
          strong, span {
            display: block;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }
          em {
            display: block;
            min-width: 0;
            font-style: normal;
          }
          strong {
            font-size: 15px;
            font-weight: 610;
          }
          span {
            margin-top: 2px;
            color: #6d7b8e;
            font-size: 12px;
          }
          .quiet {
            padding: 8px 0;
            color: #6d7b8e;
            font-size: 14px;
            margin: 0;
          }
        </style>
      </head>
      <body>
        <main>
          <section class="shell">
            <h1>Hydrogen</h1>
            <div class="quick">
              \(section(title: "Bookmarks", links: bookmarkLinks, emptyText: "No bookmarks yet."))
              \(section(title: "Recent", links: recentLinks, emptyText: "No recent pages yet."))
            </div>
          </section>
        </main>
      </body>
    </html>
    """
    }

    private struct Link {
        let title: String
        let subtitle: String
        let url: URL
        let icon: String
    }

    private static func section(title: String, links: [Link], emptyText: String) -> String {
        if links.isEmpty {
            return """
            <section>
              <h2>\(escape(title))</h2>
              <p class="quiet">\(escape(emptyText))</p>
            </section>
            """
        }

        let rows = links.map(row).joined(separator: "\n")
        return """
        <section>
          <h2>\(escape(title))</h2>
          <div class="links">
            \(rows)
          </div>
        </section>
        """
    }

    private static func row(_ link: Link) -> String {
        """
        <a href="\(escapeAttribute(link.url.absoluteString))">
          <b class="glyph">\(escape(glyph(for: link.icon)))</b>
          <em>
            <strong>\(escape(link.title))</strong>
            <span>\(escape(link.subtitle))</span>
          </em>
        </a>
        """
    }

    private static func glyph(for icon: String) -> String {
        switch icon {
        case "star":
            return "*"
        case "clock":
            return "o"
        default:
            return "+"
        }
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func escapeAttribute(_ value: String) -> String {
        escape(value).replacingOccurrences(of: "\"", with: "&quot;")
    }
}
