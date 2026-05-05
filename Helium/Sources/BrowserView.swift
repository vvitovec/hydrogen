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
            VStack(spacing: 0) {
                BrowserToolbar(
                    addressText: $addressText,
                    isAddressFocused: $isAddressFocused,
                    isShowingTabs: $isShowingTabs,
                    isShowingLibrary: $isShowingLibrary,
                    isShowingShareSheet: $isShowingShareSheet
                )

                ProgressView(value: store.activeTab?.estimatedProgress ?? 0)
                    .opacity(store.activeTab?.isLoading == true ? 1 : 0)
                    .frame(height: 2)

                if let tab = store.activeTab {
                    BrowserWebView(tab: tab)
                        .ignoresSafeArea(edges: .bottom)
                        .id(tab.id)
                        .onAppear {
                            if tab.url == nil {
                                tab.reset()
                            }
                            addressText = tab.url?.absoluteString ?? ""
                        }
                        .onReceive(tab.$url) { url in
                            if !isAddressFocused {
                                addressText = url?.absoluteString ?? ""
                            }
                        }
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
}

private struct BrowserToolbar: View {
    @EnvironmentObject private var store: BrowserStore
    @Binding var addressText: String
    let isAddressFocused: FocusState<Bool>.Binding
    @Binding var isShowingTabs: Bool
    @Binding var isShowingLibrary: Bool
    @Binding var isShowingShareSheet: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    store.activeTab?.webView.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(store.activeTab?.canGoBack != true)

                Button {
                    store.activeTab?.webView.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(store.activeTab?.canGoForward != true)

                HStack(spacing: 6) {
                    Image(systemName: securityIconName)
                        .foregroundStyle(securityIconColor)
                        .font(.caption)

                    TextField("Search or website", text: $addressText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.webSearch)
                        .submitLabel(.go)
                        .focused(isAddressFocused)
                        .onSubmit {
                            store.loadInput(addressText)
                            isAddressFocused.wrappedValue = false
                        }

                    Button {
                        store.activeTab?.stopOrReload()
                    } label: {
                        Image(systemName: store.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 20) {
                Button {
                    store.addOrRemoveBookmarkForActiveTab()
                } label: {
                    Image(systemName: store.activeTab.map(store.isBookmarked) == true ? "star.fill" : "star")
                }
                .disabled(store.activeTab?.url == nil)

                Button {
                    isShowingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(store.activeTab?.url == nil)

                Button {
                    store.newTab(isPrivate: store.activeTab?.isPrivate ?? false)
                } label: {
                    Image(systemName: "plus")
                }

                Button {
                    isShowingTabs = true
                } label: {
                    Label("\(store.tabs.count)", systemImage: "square.on.square")
                }

                Button {
                    isShowingLibrary = true
                } label: {
                    Image(systemName: "sidebar.left")
                }
            }
            .font(.body)
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private var securityIconName: String {
        guard let tab = store.activeTab, let url = tab.url else { return "magnifyingglass" }
        if url.scheme == "https", tab.hasOnlySecureContent {
            return "lock.fill"
        }
        return "exclamationmark.triangle.fill"
    }

    private var securityIconColor: Color {
        guard let tab = store.activeTab, let url = tab.url else { return .secondary }
        if url.scheme == "https", tab.hasOnlySecureContent {
            return .green
        }
        return .orange
    }
}

private extension BrowserStore {
    func addOrRemoveBookmarkForActiveTab() {
        guard let activeTab else { return }
        addOrRemoveBookmark(for: activeTab)
    }
}
