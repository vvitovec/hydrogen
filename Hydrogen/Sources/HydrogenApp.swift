import SwiftUI

@main
struct HydrogenApp: App {
    @StateObject private var store = BrowserStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environmentObject(store)
                .onOpenURL { url in
                    store.openExternalURL(url)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active {
                        store.flushPendingSave()
                    }
                }
        }
    }
}
