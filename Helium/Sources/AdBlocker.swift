import Foundation
import WebKit

@MainActor
final class AdBlocker {
    var isEnabled = true

    private var compiledRuleList: WKContentRuleList?
    private var isCompiling = false
    private var pendingWebViews: [WeakWebView] = []

    func apply(to webView: WKWebView) {
        webView.configuration.userContentController.removeAllContentRuleLists()
        guard isEnabled else { return }

        if let compiledRuleList {
            webView.configuration.userContentController.add(compiledRuleList)
            return
        }

        pendingWebViews.append(WeakWebView(webView))
        compileIfNeeded()
    }

    private func compileIfNeeded() {
        guard !isCompiling else { return }
        isCompiling = true

        guard let url = Bundle.main.url(forResource: "BlockRules", withExtension: "json"),
              let encodedRules = try? String(contentsOf: url, encoding: .utf8) else {
            isCompiling = false
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "helium.blockrules.v1",
            encodedContentRuleList: encodedRules
        ) { [weak self] ruleList, error in
            Task { @MainActor in
                guard let self else { return }
                self.isCompiling = false

                if let error {
                    assertionFailure("Failed to compile adblock rules: \(error.localizedDescription)")
                    self.pendingWebViews.removeAll()
                    return
                }

                self.compiledRuleList = ruleList
                guard let ruleList else { return }

                let webViews = self.pendingWebViews.compactMap(\.webView)
                self.pendingWebViews.removeAll()
                webViews.forEach { webView in
                    webView.configuration.userContentController.removeAllContentRuleLists()
                    if self.isEnabled {
                        webView.configuration.userContentController.add(ruleList)
                    }
                }
            }
        }
    }
}

private struct WeakWebView {
    weak var webView: WKWebView?

    init(_ webView: WKWebView) {
        self.webView = webView
    }
}
