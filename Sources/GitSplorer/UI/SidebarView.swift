import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List(selection: $appState.selectedRepository) {
            Section("Repositories") {
                ForEach(appState.repositories) { repo in
                    Text(repo.displayName)
                        .tag(repo)
                }
                .onDelete(perform: appState.removeRepositories)
            }

            if !appState.branches.isEmpty {
                Section("Branches") {
                    ForEach(appState.branches) { branch in
                        HStack {
                            Text(branch.name)
                            if branch.isCurrent {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            if !appState.statusEntries.isEmpty {
                Section("Status") {
                    ForEach(appState.statusEntries) { entry in
                        HStack {
                            Text(entry.path)
                            Spacer()
                            Text(entry.status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .onChange(of: appState.selectedRepository) { _ in
            Task { await appState.refreshSelection() }
        }
    }
}
