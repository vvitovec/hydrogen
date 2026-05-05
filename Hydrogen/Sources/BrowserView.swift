import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var store: BrowserStore
    @State private var addressText = ""
    @State private var isShowingTabs = false
    @State private var isShowingLibrary = false
    @State private var isShowingShareSheet = false
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                HydrogenTheme.background
                    .ignoresSafeArea()

                if let tab = store.activeTab {
                    if let webView = tab.webView {
                        BrowserWebView(webView: webView)
                            .ignoresSafeArea()
                            .id(tab.webViewID)
                            .onAppear {
                                syncAddress(from: tab)
                            }
                            .onReceive(tab.$url) { url in
                                guard !isAddressFocused else { return }
                                addressText = url?.absoluteString ?? ""
                            }
                    } else {
                        NativeStartPageView(
                            bookmarks: store.bookmarks,
                            history: store.history,
                            onOpen: { url in
                                store.open(url)
                            }
                        )
                    }
                }

                VStack(spacing: 0) {
                    if let tab = store.activeTab {
                        BrowserProgressLine(tab: tab)
                    }
                    Spacer()
                }
                .allowsHitTesting(false)

                if let tab = store.activeTab {
                    BrowserCommandBar(
                        tab: tab,
                        addressText: $addressText,
                        isAddressFocused: $isAddressFocused,
                        isShowingTabs: $isShowingTabs,
                        isShowingLibrary: $isShowingLibrary,
                        isShowingShareSheet: $isShowingShareSheet
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: store.activeTabID) { _, _ in
                syncAddress(from: store.activeTab)
            }
        }
        .sheet(isPresented: $isShowingTabs) {
            TabOverviewView()
                .environmentObject(store)
        }
        .sheet(isPresented: $isShowingLibrary) {
            LibraryView()
                .environmentObject(store)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareSheet(items: store.shareItems())
        }
    }

    private func syncAddress(from tab: BrowserTab?) {
        guard !isAddressFocused else { return }
        addressText = tab?.url?.absoluteString ?? ""
    }
}

private struct BrowserProgressLine: View {
    @ObservedObject var tab: BrowserTab

    var body: some View {
        ProgressView(value: tab.estimatedProgress)
            .tint(HydrogenTheme.helium)
            .opacity(tab.isLoading ? 1 : 0)
            .frame(height: 2)
    }
}

private struct NativeStartPageView: View {
    let bookmarks: [BookmarkItem]
    let history: [HistoryItem]
    let onOpen: (URL) -> Void

    private var links: (bookmarks: [StartPageLink], recent: [StartPageLink]) {
        let bookmarkedURLs = Set(bookmarks.map(\.url))
        let bookmarkLinks = bookmarks.prefix(4).map {
            StartPageLink(
                title: $0.title,
                subtitle: $0.url.host(percentEncoded: false) ?? $0.url.absoluteString,
                url: $0.url,
                icon: "star"
            )
        }
        let recentLinks = history
            .filter { !bookmarkedURLs.contains($0.url) }
            .prefix(4)
            .map {
                StartPageLink(
                    title: $0.title,
                    subtitle: $0.url.host(percentEncoded: false) ?? $0.url.absoluteString,
                    url: $0.url,
                    icon: "clock"
                )
            }

        return (bookmarkLinks, recentLinks)
    }

    var body: some View {
        let pageLinks = links

        ScrollView {
            VStack(alignment: .leading, spacing: 46) {
                Text("Hydrogen")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(HydrogenTheme.ink)

                VStack(spacing: 30) {
                    StartPageSection(
                        title: "Bookmarks",
                        emptyText: "No bookmarks yet.",
                        links: pageLinks.bookmarks,
                        onOpen: onOpen
                    )

                    StartPageSection(
                        title: "Recent",
                        emptyText: "No recent pages yet.",
                        links: pageLinks.recent,
                        onOpen: onOpen
                    )
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.top, 62)
            .padding(.bottom, 118)
        }
        .background(HydrogenTheme.background)
    }
}

private struct StartPageSection: View {
    let title: String
    let emptyText: String
    let links: [StartPageLink]
    let onOpen: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(HydrogenTheme.faintInk)

            if links.isEmpty {
                Text(emptyText)
                    .font(.system(size: 14))
                    .foregroundStyle(HydrogenTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(links) { link in
                        Button {
                            onOpen(link.url)
                        } label: {
                            StartPageRow(link: link)
                        }
                        .buttonStyle(.plain)

                        if link.id != links.last?.id {
                            Divider()
                                .overlay(HydrogenTheme.hairline.opacity(0.45))
                        }
                    }
                }
                .overlay(alignment: .top) {
                    Divider()
                        .overlay(HydrogenTheme.hairline.opacity(0.45))
                }
                .overlay(alignment: .bottom) {
                    Divider()
                        .overlay(HydrogenTheme.hairline.opacity(0.45))
                }
            }
        }
    }
}

private struct StartPageRow: View {
    let link: StartPageLink

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: link.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HydrogenTheme.helium)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HydrogenTheme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(link.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(HydrogenTheme.mutedInk)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 46)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

private struct StartPageLink: Identifiable {
    let title: String
    let subtitle: String
    let url: URL
    let icon: String

    var id: String { url.absoluteString }
}

private struct BrowserCommandBar: View {
    @EnvironmentObject private var store: BrowserStore
    @ObservedObject var tab: BrowserTab
    @Binding var addressText: String
    let isAddressFocused: FocusState<Bool>.Binding
    @Binding var isShowingTabs: Bool
    @Binding var isShowingLibrary: Bool
    @Binding var isShowingShareSheet: Bool

    private var isFocused: Bool {
        isAddressFocused.wrappedValue
    }

    var body: some View {
        HStack(spacing: 6) {
            if !isFocused {
                CommandIconButton(
                    systemName: "chevron.left",
                    title: "Back",
                    isEnabled: tab.canGoBack
                ) {
                    tab.goBack()
                }

                CommandIconButton(
                    systemName: "chevron.right",
                    title: "Forward",
                    isEnabled: tab.canGoForward
                ) {
                    tab.goForward()
                }
            }

            addressField

            if isFocused {
                Button("Cancel") {
                    isAddressFocused.wrappedValue = false
                    addressText = tab.url?.absoluteString ?? ""
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HydrogenTheme.ink)
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
            } else {
                CommandIconButton(
                    systemName: tab.isLoading ? "xmark" : "arrow.clockwise",
                    title: tab.isLoading ? "Stop" : "Reload",
                    isEnabled: tab.url != nil || tab.isLoading
                ) {
                    tab.stopOrReload()
                }

                tabsButton

                moreMenu
            }
        }
        .padding(6)
        .background(HydrogenTheme.elevatedSurface.opacity(0.98), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: HydrogenTheme.ink.opacity(0.08), radius: 8, x: 0, y: 4)
        .animation(.snappy(duration: 0.18), value: isFocused)
    }

    private var addressField: some View {
        HStack(spacing: 7) {
            Image(systemName: securityIconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(securityIconColor)
                .frame(width: 14)

            TextField("Search or website", text: $addressText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .focused(isAddressFocused)
                .accessibilityIdentifier("AddressField")
                .onSubmit {
                    store.loadInput(addressText)
                    isAddressFocused.wrappedValue = false
                }

            if isFocused, !addressText.isEmpty {
                Button {
                    addressText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HydrogenTheme.faintInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear address")
            }
        }
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(HydrogenTheme.ink)
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(HydrogenTheme.elevatedSurface.opacity(0.94), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(isFocused ? 0.95 : 0.45), lineWidth: 1)
        }
    }

    private var tabsButton: some View {
        Button {
            isShowingTabs = true
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 16, weight: .semibold))

                Text(tabCountText)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(HydrogenTheme.surface)
                    .frame(minWidth: 14, minHeight: 14)
                    .background(HydrogenTheme.ink, in: Capsule())
                    .offset(x: 7, y: 7)
            }
            .frame(width: 32, height: 34)
            .foregroundStyle(HydrogenTheme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tabs")
    }

    private var moreMenu: some View {
        Menu {
            Button {
                openLibrary(.bookmarks)
            } label: {
                Label("Bookmarks", systemImage: "star")
            }

            Button {
                openLibrary(.history)
            } label: {
                Label("History", systemImage: "clock")
            }

            Button {
                openLibrary(.settings)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            Button {
                store.newTab(isPrivate: tab.isPrivate)
            } label: {
                Label("New Tab", systemImage: "plus")
            }

            Button {
                store.newTab(isPrivate: true)
            } label: {
                Label("New Private Tab", systemImage: "eye.slash")
            }

            Divider()

            Button {
                store.addOrRemoveBookmarkForActiveTab()
            } label: {
                Label(bookmarkTitle, systemImage: bookmarkIconName)
            }
            .disabled(tab.url == nil)

            Button {
                isShowingShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(tab.url == nil)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 34)
                .foregroundStyle(HydrogenTheme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More")
    }

    private func openLibrary(_ mode: LibraryMode) {
        store.libraryMode = mode
        isShowingLibrary = true
    }

    private var tabCountText: String {
        store.tabs.count > 99 ? "99" : "\(store.tabs.count)"
    }

    private var bookmarkTitle: String {
        return store.isBookmarked(tab) ? "Remove Bookmark" : "Bookmark"
    }

    private var bookmarkIconName: String {
        return store.isBookmarked(tab) ? "star.slash" : "star"
    }

    private var securityIconName: String {
        guard let url = tab.url else { return "magnifyingglass" }
        if tab.isPrivate {
            return "eye.slash.fill"
        }
        if url.scheme == "https", tab.hasOnlySecureContent {
            return "lock.fill"
        }
        return "exclamationmark.triangle.fill"
    }

    private var securityIconColor: Color {
        guard let url = tab.url else { return HydrogenTheme.faintInk }
        if tab.isPrivate {
            return HydrogenTheme.privateTint
        }
        if url.scheme == "https", tab.hasOnlySecureContent {
            return HydrogenTheme.helium
        }
        return HydrogenTheme.warning
    }
}

private struct CommandIconButton: View {
    let systemName: String
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 34)
                .foregroundStyle(isEnabled ? HydrogenTheme.ink : HydrogenTheme.faintInk)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private extension BrowserStore {
    func addOrRemoveBookmarkForActiveTab() {
        guard let activeTab else { return }
        addOrRemoveBookmark(for: activeTab)
    }
}
