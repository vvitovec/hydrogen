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
                    BrowserWebView(tab: tab)
                        .ignoresSafeArea()
                        .id(tab.id)
                        .onAppear {
                            syncAddress(from: tab)
                        }
                        .onReceive(tab.$url) { url in
                            guard !isAddressFocused else { return }
                            addressText = url?.absoluteString ?? ""
                        }
                }

                VStack(spacing: 0) {
                    ProgressView(value: store.activeTab?.estimatedProgress ?? 0)
                        .tint(HydrogenTheme.helium)
                        .opacity(store.activeTab?.isLoading == true ? 1 : 0)
                        .frame(height: 2)
                    Spacer()
                }
                .allowsHitTesting(false)

                BrowserCommandBar(
                    addressText: $addressText,
                    isAddressFocused: $isAddressFocused,
                    isShowingTabs: $isShowingTabs,
                    isShowingLibrary: $isShowingLibrary,
                    isShowingShareSheet: $isShowingShareSheet
                )
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
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

private struct BrowserCommandBar: View {
    @EnvironmentObject private var store: BrowserStore
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
                    isEnabled: store.activeTab?.canGoBack == true
                ) {
                    store.activeTab?.webView.goBack()
                }

                CommandIconButton(
                    systemName: "chevron.right",
                    title: "Forward",
                    isEnabled: store.activeTab?.canGoForward == true
                ) {
                    store.activeTab?.webView.goForward()
                }
            }

            addressField

            if isFocused {
                Button("Cancel") {
                    isAddressFocused.wrappedValue = false
                    addressText = store.activeTab?.url?.absoluteString ?? ""
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HydrogenTheme.ink)
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
            } else {
                CommandIconButton(
                    systemName: store.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise",
                    title: store.activeTab?.isLoading == true ? "Stop" : "Reload",
                    isEnabled: store.activeTab != nil
                ) {
                    store.activeTab?.stopOrReload()
                }

                tabsButton

                CommandIconButton(systemName: "sidebar.left", title: "Library") {
                    isShowingLibrary = true
                }

                moreMenu
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: HydrogenTheme.ink.opacity(0.12), radius: 16, x: 0, y: 8)
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
                store.newTab(isPrivate: store.activeTab?.isPrivate ?? false)
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
            .disabled(store.activeTab?.url == nil)

            Button {
                isShowingShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(store.activeTab?.url == nil)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 32, height: 34)
                .foregroundStyle(HydrogenTheme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More")
    }

    private var tabCountText: String {
        store.tabs.count > 99 ? "99" : "\(store.tabs.count)"
    }

    private var bookmarkTitle: String {
        guard let tab = store.activeTab else { return "Bookmark" }
        return store.isBookmarked(tab) ? "Remove Bookmark" : "Bookmark"
    }

    private var bookmarkIconName: String {
        guard let tab = store.activeTab else { return "star" }
        return store.isBookmarked(tab) ? "star.slash" : "star"
    }

    private var securityIconName: String {
        guard let tab = store.activeTab, let url = tab.url else { return "magnifyingglass" }
        if tab.isPrivate {
            return "eye.slash.fill"
        }
        if url.scheme == "https", tab.hasOnlySecureContent {
            return "lock.fill"
        }
        return "exclamationmark.triangle.fill"
    }

    private var securityIconColor: Color {
        guard let tab = store.activeTab, let url = tab.url else { return HydrogenTheme.faintInk }
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
