import SwiftUI

struct TabOverviewView: View {
    @EnvironmentObject private var store: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.tabs) { tab in
                        Button {
                            store.selectTab(tab)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.isPrivate ? "eye.slash" : "globe")
                                    .foregroundStyle(tab.isPrivate ? .purple : .secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tab.displayTitle)
                                        .lineLimit(1)
                                    Text(tab.url?.absoluteString ?? "New Tab")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if tab.id == store.activeTabID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.closeTab(tab)
                            } label: {
                                Label("Close", systemImage: "xmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tabs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.newTab(isPrivate: true)
                        dismiss()
                    } label: {
                        Image(systemName: "eye.slash")
                    }

                    Button {
                        store.newTab(isPrivate: false)
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
