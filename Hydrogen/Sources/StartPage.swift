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
            background: #f4f1e9;
            color: #1d1f19;
            -webkit-font-smoothing: antialiased;
          }
          main {
            min-height: 100%;
            display: flex;
            align-items: flex-start;
            justify-content: center;
            padding: 58px 22px 118px;
            box-sizing: border-box;
          }
          section.shell {
            width: min(100%, 560px);
          }
          .mark {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 22px;
            color: #68734a;
            font-size: 13px;
            font-weight: 650;
            letter-spacing: .04em;
            text-transform: uppercase;
          }
          .dot {
            width: 9px;
            height: 9px;
            border-radius: 999px;
            background: #8aa158;
          }
          h1 {
            font-size: 38px;
            line-height: 1;
            font-weight: 720;
            margin: 0 0 12px;
            letter-spacing: 0;
          }
          p {
            margin: 0;
            color: #676b62;
          }
          .lede {
            font-size: 16px;
            line-height: 1.45;
            max-width: 34ch;
          }
          .quick {
            display: grid;
            gap: 14px;
            margin-top: 36px;
          }
          h2 {
            margin: 0 0 8px;
            font-size: 12px;
            line-height: 1;
            color: #757966;
            font-weight: 650;
            letter-spacing: .05em;
            text-transform: uppercase;
          }
          .links {
            display: grid;
            gap: 8px;
          }
          a {
            display: grid;
            grid-template-columns: 28px minmax(0, 1fr);
            gap: 10px;
            align-items: center;
            min-height: 44px;
            padding: 8px 10px 8px 8px;
            color: inherit;
            text-decoration: none;
            background: rgba(255, 253, 245, .78);
            border: 1px solid rgba(168, 168, 146, .5);
            border-radius: 8px;
            box-sizing: border-box;
          }
          .glyph {
            display: grid;
            place-items: center;
            width: 28px;
            height: 28px;
            border-radius: 7px;
            background: #ebe8dc;
            color: #68734a;
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
            color: #737766;
            font-size: 12px;
          }
          .quiet {
            padding: 10px 0;
            color: #737766;
            font-size: 14px;
          }
        </style>
      </head>
      <body>
        <main>
          <section class="shell">
            <div class="mark"><i class="dot"></i> Helium mode</div>
            <h1>Hydrogen</h1>
            <p class="lede">A quiet browser shell for getting to the page fast. Search or enter a website in the command bar.</p>
            <div class="quick">
              \(section(title: "Bookmarks", links: bookmarkLinks, emptyText: "Bookmark a page and it will stay close."))
              \(section(title: "Recent", links: recentLinks, emptyText: "Visited pages appear here after regular browsing."))
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
