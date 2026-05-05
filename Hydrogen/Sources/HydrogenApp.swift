import SwiftUI
import UIKit

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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    store.handleMemoryPressure()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        store.prepareForBackground()
                    } else if phase != .active {
                        store.flushPendingSave()
                    }
                }
        }
    }
}
