import SwiftUI

struct RemoteExplorerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let message = appState.remoteErrorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            if appState.remoteAccounts.isEmpty {
                EmptyRemoteView()
            } else if appState.remoteRepositories.isEmpty {
                EmptyRemoteRepositoriesView()
            } else {
                List(appState.remoteRepositories) { repo in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(repo.fullName)
                                    .font(.headline)
                                if repo.isPrivate {
                                    Text("Private")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.15), in: Capsule())
                                }
                            }
                            if !repo.description.isEmpty {
                                Text(repo.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Clone") {
                            Task { await appState.clone(remote: repo) }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if appState.isLoadingRemote {
                ProgressView()
                    .padding(8)
            }
        }
        .onChange(of: appState.selectedRemoteAccount) { _ in
            Task { await appState.refreshRemoteRepositories() }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Remote Repositories")
                .font(.headline)
            Spacer()
            if !appState.remoteAccounts.isEmpty {
                Picker("Account", selection: $appState.selectedRemoteAccount) {
                    ForEach(appState.remoteAccounts) { account in
                        Text("\(account.provider.rawValue.capitalized) • \(account.username)")
                            .tag(Optional(account))
                    }
                }
                .frame(maxWidth: 320)
                Button("Refresh") {
                    Task { await appState.refreshRemoteRepositories() }
                }
            }
        }
        .padding()
    }
}

private struct EmptyRemoteView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 42))
            Text("Connect GitHub or GitLab in Settings")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EmptyRemoteRepositoriesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 42))
            Text("No remote repositories loaded yet")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
