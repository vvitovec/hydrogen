import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Library", selection: $store.libraryMode) {
                    ForEach(LibraryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                content
            }
            .navigationTitle(store.libraryMode.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.libraryMode {
        case .bookmarks:
            List {
                if store.bookmarks.isEmpty {
                    ContentUnavailableView("No Bookmarks", systemImage: "star", description: Text("Bookmark pages from the browser toolbar."))
                } else {
                    ForEach(store.bookmarks) { bookmark in
                        Button {
                            store.open(bookmark.url)
                            dismiss()
                        } label: {
                            LibraryRow(title: bookmark.title, subtitle: bookmark.url.absoluteString, icon: "star")
                        }
                    }
                    .onDelete(perform: store.deleteBookmarks)
                }
            }

        case .history:
            List {
                if store.history.isEmpty {
                    ContentUnavailableView("No History", systemImage: "clock", description: Text("Regular browsing history appears here."))
                } else {
                    ForEach(store.history) { item in
                        Button {
                            store.open(item.url)
                            dismiss()
                        } label: {
                            LibraryRow(title: item.title, subtitle: item.url.absoluteString, icon: "clock")
                        }
                    }
                    .onDelete(perform: store.deleteHistory)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        store.clearHistory()
                    }
                    .disabled(store.history.isEmpty)
                }
            }

        case .settings:
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { store.settings.isAdBlockEnabled },
                        set: { store.setAdBlockEnabled($0) }
                    )) {
                        Label("Ad Blocker", systemImage: "shield.lefthalf.filled")
                    }
                }

                Section {
                    LabeledContent("Search", value: "DuckDuckGo")
                    LabeledContent("Private tabs", value: "Memory only")
                }
            }
        }
    }
}

private struct LibraryRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
