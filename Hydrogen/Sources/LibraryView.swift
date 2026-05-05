import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: BrowserStore
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingClearHistory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Library", selection: $store.libraryMode) {
                    ForEach(LibraryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .tint(HydrogenTheme.helium)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                content
            }
            .background(HydrogenTheme.background.ignoresSafeArea())
            .navigationTitle(store.libraryMode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if store.libraryMode == .history {
                        Button("Clear") {
                            isConfirmingClearHistory = true
                        }
                        .disabled(store.history.isEmpty)
                    }
                }
            }
            .confirmationDialog("Clear browsing history?", isPresented: $isConfirmingClearHistory, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) {
                    store.clearHistory()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                switch store.libraryMode {
                case .bookmarks:
                    bookmarksContent
                case .history:
                    historyContent
                case .settings:
                    settingsContent
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var bookmarksContent: some View {
        if store.bookmarks.isEmpty {
            EmptyLibraryState(title: "No Bookmarks", message: "Saved pages will appear here.", icon: "star")
        } else {
            ForEach(store.bookmarks) { bookmark in
                LibraryEntryRow(
                    title: bookmark.title,
                    subtitle: bookmark.url.absoluteString,
                    icon: "star",
                    onOpen: {
                        store.open(bookmark.url)
                        dismiss()
                    },
                    onDelete: {
                        guard let index = store.bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
                        store.deleteBookmarks(at: IndexSet(integer: index))
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        if store.history.isEmpty {
            EmptyLibraryState(title: "No History", message: "Regular browsing history appears here.", icon: "clock")
        } else {
            ForEach(store.history) { item in
                LibraryEntryRow(
                    title: item.title,
                    subtitle: item.url.absoluteString,
                    icon: "clock",
                    onOpen: {
                        store.open(item.url)
                        dismiss()
                    },
                    onDelete: {
                        guard let index = store.history.firstIndex(where: { $0.id == item.id }) else { return }
                        store.deleteHistory(at: IndexSet(integer: index))
                    }
                )
            }
        }
    }

    private var settingsContent: some View {
        VStack(spacing: 12) {
            SettingsToggleRow(
                title: "Ad Blocker",
                detail: "Blocks ads and trackers with bundled WebKit rules.",
                icon: "shield.lefthalf.filled",
                isOn: Binding(
                    get: { store.settings.isAdBlockEnabled },
                    set: { store.setAdBlockEnabled($0) }
                )
            )

            SettingsInfoRow(title: "Search", value: "DuckDuckGo", icon: "magnifyingglass")
            SettingsInfoRow(title: "Private Tabs", value: "Memory only", icon: "eye.slash")
            SettingsInfoRow(title: "History Limit", value: "500 visits", icon: "clock.arrow.circlepath")
        }
    }
}

private struct LibraryEntryRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 11) {
                    glyph

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(HydrogenTheme.ink)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(HydrogenTheme.mutedInk)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 8)
                }
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HydrogenTheme.mutedInk)
                    .frame(width: 30, height: 30)
                    .background(HydrogenTheme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete")
        }
        .padding(10)
        .background(HydrogenTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.55), lineWidth: 1)
        }
    }

    private var glyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HydrogenTheme.helium.opacity(0.13))

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HydrogenTheme.helium)
        }
        .frame(width: 40, height: 40)
    }
}

private struct EmptyLibraryState: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(HydrogenTheme.faintInk)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(HydrogenTheme.ink)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(HydrogenTheme.mutedInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 38)
        .padding(.horizontal, 20)
        .background(HydrogenTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 11) {
            settingGlyph

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HydrogenTheme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(HydrogenTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(HydrogenTheme.helium)
        }
        .padding(12)
        .background(HydrogenTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.55), lineWidth: 1)
        }
    }

    private var settingGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(HydrogenTheme.helium.opacity(0.13))

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HydrogenTheme.helium)
        }
        .frame(width: 40, height: 40)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(HydrogenTheme.helium.opacity(0.13))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HydrogenTheme.helium)
            }
            .frame(width: 40, height: 40)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HydrogenTheme.ink)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HydrogenTheme.mutedInk)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(12)
        .background(HydrogenTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(HydrogenTheme.hairline.opacity(0.55), lineWidth: 1)
        }
    }
}
