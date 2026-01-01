import SwiftUI

@main
struct GitSplorerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
