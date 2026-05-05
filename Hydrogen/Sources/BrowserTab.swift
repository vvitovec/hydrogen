import Foundation
import WebKit

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable {
    let id = UUID()
    let isPrivate: Bool
    let webView: WKWebView

    @Published var title: String = "New Tab"
    @Published var url: URL?
    @Published var estimatedProgress: Double = 0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var hasOnlySecureContent = false

    var onVisited: ((String, URL) -> Void)?
    var onOpenNewTab: ((URLRequest) -> Void)?
    var onOpenExternal: ((URL) -> Void)?

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != "New Tab" {
            return trimmed
        }
        return url?.host(percentEncoded: false) ?? "New Tab"
    }

    init(isPrivate: Bool) {
        self.isPrivate = isPrivate

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        self.webView = webView
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        refreshState()
    }

    func load(_ request: URLRequest) {
        webView.load(request)
        refreshState()
    }

    func reload() {
        if webView.url == nil {
            return
        }
        webView.reload()
    }

    func stopOrReload() {
        if isLoading {
            webView.stopLoading()
        } else {
            reload()
        }
        refreshState()
    }

    func reset() {
        webView.stopLoading()
        webView.loadHTMLString(StartPage.html, baseURL: nil)
        title = "New Tab"
        url = nil
        estimatedProgress = 0
        refreshState()
    }

    private func refreshState() {
        title = webView.title ?? title
        url = webView.url.flatMap { URLNormalizer.isInternalStartURL($0) ? nil : $0 }
        estimatedProgress = webView.estimatedProgress
        isLoading = webView.isLoading
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        hasOnlySecureContent = webView.hasOnlySecureContent
    }
}

extension BrowserTab: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        refreshState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshState()
        if let url = url {
            onVisited?(displayTitle, url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshState()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .cancel
        }

        if URLNormalizer.isInternalStartURL(url) || URLNormalizer.isWebURL(url) {
            return .allow
        }

        onOpenExternal?(url)
        return .cancel
    }
}

extension BrowserTab: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else {
            return nil
        }

        onOpenNewTab?(navigationAction.request)
        return nil
    }
}
