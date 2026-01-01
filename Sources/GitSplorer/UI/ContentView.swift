import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            FileTreeView()
        } detail: {
            DetailView()
        }
        .navigationTitle(appState.selectedRepository?.displayName ?? "GitSplorer")
        .toolbar {
            ToolbarItemGroup {
                Button(action: addRepository) {
                    Label("Add Repository", systemImage: "plus")
                }
                Button(action: { Task { await appState.refreshSelection() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(appState.selectedRepository == nil)
            }
        }
    }

    private func addRepository() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Git Repository"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"

        if panel.runModal() == .OK, let url = panel.url {
            appState.addRepository(url: url)
        }
    }
}
