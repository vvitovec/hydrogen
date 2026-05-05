import Foundation
import WebKit

@MainActor
final class AdBlocker {
    private static let ruleListIdentifier = "hydrogen.blockrules.v1"

    var isEnabled = true

    private var compiledRuleList: WKContentRuleList?
    private var isLoadingRuleList = false
    private var pendingWebViews: [WeakWebView] = []

    func prepare() {
        guard isEnabled else { return }
        loadRuleListIfNeeded()
    }

    func apply(to webView: WKWebView) {
        webView.configuration.userContentController.removeAllContentRuleLists()
        guard isEnabled else { return }

        if let compiledRuleList {
            webView.configuration.userContentController.add(compiledRuleList)
            return
        }

        pendingWebViews.append(WeakWebView(webView))
        loadRuleListIfNeeded()
    }

    private func loadRuleListIfNeeded() {
        guard compiledRuleList == nil else { return }
        guard !isLoadingRuleList else { return }
        isLoadingRuleList = true

        WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: Self.ruleListIdentifier) { [weak self] ruleList, _ in
            Task { @MainActor in
                guard let self else { return }
                if let ruleList {
                    self.isLoadingRuleList = false
                    self.compiledRuleList = ruleList
                    self.applyPendingWebViews(ruleList)
                    return
                }

                self.compileRuleList()
            }
        }
    }

    private func compileRuleList() {
        guard let url = Bundle.main.url(forResource: "BlockRules", withExtension: "json"),
              let encodedRules = try? String(contentsOf: url, encoding: .utf8) else {
            isLoadingRuleList = false
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: Self.ruleListIdentifier,
            encodedContentRuleList: encodedRules
        ) { [weak self] ruleList, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoadingRuleList = false

                if let error {
                    assertionFailure("Failed to compile adblock rules: \(error.localizedDescription)")
                    self.pendingWebViews.removeAll()
                    return
                }

                self.compiledRuleList = ruleList
                guard let ruleList else { return }
                self.applyPendingWebViews(ruleList)
            }
        }
    }

    private func applyPendingWebViews(_ ruleList: WKContentRuleList) {
        let webViews = pendingWebViews.compactMap(\.webView)
        pendingWebViews.removeAll()
        webViews.forEach { webView in
            webView.configuration.userContentController.removeAllContentRuleLists()
            if isEnabled {
                webView.configuration.userContentController.add(ruleList)
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
