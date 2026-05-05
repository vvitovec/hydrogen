import SwiftUI

@main
struct HydrogenApp: App {
    @StateObject private var store = BrowserStore()

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environmentObject(store)
                .onOpenURL { url in
                    store.openExternalURL(url)
                }
        }
    }
}
