import Foundation
import WebKit

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable {
    private static let progressPublishStep = 0.025

    let id = UUID()
    let isPrivate: Bool

    @Published private(set) var webView: WKWebView?
    @Published private(set) var webViewID = UUID()
    @Published private(set) var isSuspended = false
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
    var onWebViewCreated: ((WKWebView) -> Void)?

    private var observations: [NSKeyValueObservation] = []

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != "New Tab" {
            return trimmed
        }
        return url?.host(percentEncoded: false) ?? "New Tab"
    }

    init(isPrivate: Bool, onWebViewCreated: ((WKWebView) -> Void)? = nil) {
        self.isPrivate = isPrivate
        self.onWebViewCreated = onWebViewCreated
        super.init()
    }

    @discardableResult
    func ensureWebView() -> WKWebView {
        if let webView {
            return webView
        }

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
        webViewID = UUID()
        isSuspended = false
        configure(webView)
        onWebViewCreated?(webView)
        refreshState(forceProgress: true)
        return webView
    }

    func restore() {
        if let url {
            load(URLRequest(url: url))
        } else {
            reset()
        }
    }

    func load(_ request: URLRequest) {
        ensureWebView().load(request)
        refreshState(forceProgress: true)
    }

    func reload() {
        guard let webView else {
            if let url {
                load(URLRequest(url: url))
            }
            return
        }

        if webView.url == nil {
            return
        }
        webView.reload()
    }

    func stopOrReload() {
        if isLoading {
            webView?.stopLoading()
        } else {
            reload()
        }
        refreshState(forceProgress: true)
    }

    func goBack() {
        webView?.goBack()
        refreshState()
    }

    func goForward() {
        webView?.goForward()
        refreshState()
    }

    func reset() {
        if let webView {
            dismantle(webView)
            self.webView = nil
            webViewID = UUID()
        }
        observations.removeAll()
        isSuspended = false
        applyState(
            title: "New Tab",
            url: nil,
            estimatedProgress: 0,
            isLoading: false,
            canGoBack: false,
            canGoForward: false,
            hasOnlySecureContent: false,
            forceProgress: true
        )
    }

    func suspend() {
        guard let webView else {
            isSuspended = true
            return
        }

        let suspendedTitle = title
        let suspendedURL = url
        let suspendedSecureContent = hasOnlySecureContent
        dismantle(webView)
        self.webView = nil
        webViewID = UUID()
        isSuspended = true
        applyState(
            title: suspendedTitle,
            url: suspendedURL,
            estimatedProgress: suspendedURL == nil ? 0 : 1,
            isLoading: false,
            canGoBack: false,
            canGoForward: false,
            hasOnlySecureContent: suspendedSecureContent,
            forceProgress: true
        )
    }

    func tearDown() {
        if let webView {
            dismantle(webView)
            self.webView = nil
            webViewID = UUID()
        }
        isSuspended = false
    }

    private func configure(_ webView: WKWebView) {
        webView.navigationDelegate = self
        webView.uiDelegate = self
        observe(webView)
    }

    private func dismantle(_ webView: WKWebView) {
        observations.removeAll()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.configuration.userContentController.removeAllContentRuleLists()
        webView.loadHTMLString("", baseURL: nil)
    }

    private func refreshState(forceProgress: Bool = false) {
        guard let webView else { return }
        applyState(
            title: webView.title ?? title,
            url: webView.url.flatMap { URLNormalizer.isInternalStartURL($0) ? nil : $0 },
            estimatedProgress: webView.estimatedProgress,
            isLoading: webView.isLoading,
            canGoBack: webView.canGoBack,
            canGoForward: webView.canGoForward,
            hasOnlySecureContent: webView.hasOnlySecureContent,
            forceProgress: forceProgress
        )
    }

    private func observe(_ webView: WKWebView) {
        observations = [
            webView.observe(\.title, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            },
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState(forceProgress: true) }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            },
            webView.observe(\.hasOnlySecureContent, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.refreshState() }
            }
        ]
    }

    private func applyState(
        title: String,
        url: URL?,
        estimatedProgress: Double,
        isLoading: Bool,
        canGoBack: Bool,
        canGoForward: Bool,
        hasOnlySecureContent: Bool,
        forceProgress: Bool = false
    ) {
        if self.title != title {
            self.title = title
        }
        if self.url != url {
            self.url = url
        }
        if shouldPublishProgress(estimatedProgress, force: forceProgress) {
            self.estimatedProgress = estimatedProgress
        }
        if self.isLoading != isLoading {
            self.isLoading = isLoading
        }
        if self.canGoBack != canGoBack {
            self.canGoBack = canGoBack
        }
        if self.canGoForward != canGoForward {
            self.canGoForward = canGoForward
        }
        if self.hasOnlySecureContent != hasOnlySecureContent {
            self.hasOnlySecureContent = hasOnlySecureContent
        }
    }

    private func shouldPublishProgress(_ progress: Double, force: Bool) -> Bool {
        force || progress == 0 || progress >= 1 || abs(estimatedProgress - progress) >= Self.progressPublishStep
    }
}

extension BrowserTab: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        refreshState(forceProgress: true)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshState(forceProgress: true)
        if let url = url {
            onVisited?(displayTitle, url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshState(forceProgress: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshState(forceProgress: true)
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
