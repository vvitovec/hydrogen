import SwiftUI

struct TabOverviewView: View {
    @EnvironmentObject private var store: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.tabs) { tab in
                        TabOverviewRow(
                            tab: tab,
                            isActive: tab.id == store.activeTabID,
                            onSelect: {
                                store.selectTab(tab)
                                dismiss()
                            },
                            onClose: {
                                store.closeTab(tab)
                            }
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 92)
            }
            .background(HydrogenTheme.background.ignoresSafeArea())
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button {
                        store.newTab(isPrivate: false)
                        dismiss()
                    } label: {
                        Label("New Tab", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TabActionButtonStyle())

                    Button {
                        store.newTab(isPrivate: true)
                        dismiss()
                    } label: {
                        Label("Private", systemImage: "eye.slash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TabActionButtonStyle(tint: HydrogenTheme.privateTint))
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
}

private struct TabOverviewRow: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 11) {
                    tabGlyph

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(tab.displayTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(HydrogenTheme.ink)
                                .lineLimit(1)

                            if tab.isPrivate {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(HydrogenTheme.privateTint)
                            }
                        }

                        Text(tab.url?.absoluteString ?? "New Tab")
                            .font(.system(size: 12))
                            .foregroundStyle(HydrogenTheme.mutedInk)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(HydrogenTheme.helium)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .buttonStyle(.plain)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HydrogenTheme.mutedInk)
                    .frame(width: 30, height: 30)
                    .background(HydrogenTheme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close tab")
        }
        .padding(10)
        .background(HydrogenTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isActive ? HydrogenTheme.helium.opacity(0.9) : HydrogenTheme.hairline.opacity(0.55), lineWidth: 1)
        }
    }

    private var tabGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tab.isPrivate ? HydrogenTheme.privateTint.opacity(0.14) : HydrogenTheme.helium.opacity(0.13))

            Image(systemName: tab.isPrivate ? "eye.slash" : "globe")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tab.isPrivate ? HydrogenTheme.privateTint : HydrogenTheme.helium)
        }
        .frame(width: 40, height: 40)
    }
}

private struct TabActionButtonStyle: ButtonStyle {
    var tint = HydrogenTheme.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(HydrogenTheme.elevatedSurface.opacity(configuration.isPressed ? 0.75 : 0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(HydrogenTheme.hairline.opacity(0.65), lineWidth: 1)
            }
    }
}
