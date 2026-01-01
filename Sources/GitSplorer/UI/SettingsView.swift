import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("GitHub OAuth") {
                RemoteProviderConfigView(config: configBinding(for: .github), showBaseURL: false)
                Button("Connect GitHub") {
                    Task { await appState.connectRemote(GitHubProvider()) }
                }
                .disabled(!canConnect(.github))
            }

            Section("GitLab OAuth") {
                RemoteProviderConfigView(config: configBinding(for: .gitlab), showBaseURL: true)
                Button("Connect GitLab") {
                    Task { await appState.connectRemote(GitLabProvider()) }
                }
                .disabled(!canConnect(.gitlab))
            }

            Section("Remote Status") {
                if let message = appState.remoteErrorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                } else {
                    Text("No remote errors. Tokens are stored in Keychain.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Connected Accounts") {
                if appState.remoteAccounts.isEmpty {
                    Text("No accounts connected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.remoteAccounts) { account in
                        HStack {
                            Text(account.provider.rawValue.capitalized)
                            Spacer()
                            Text(account.username)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 420)
    }

    private func configBinding(for kind: RemoteProviderKind) -> Binding<RemoteProviderConfiguration> {
        Binding(
            get: { appState.remoteConfigs[kind] ?? .defaults(for: kind) },
            set: { appState.saveRemoteConfig($0, for: kind) }
        )
    }

    private func canConnect(_ kind: RemoteProviderKind) -> Bool {
        let config = appState.remoteConfigs[kind] ?? .defaults(for: kind)
        return !config.clientId.isEmpty && !config.redirectURI.isEmpty
    }
}

private struct RemoteProviderConfigView: View {
    @Binding var config: RemoteProviderConfiguration
    let showBaseURL: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Client ID", text: $config.clientId)
            SecureField("Client Secret (optional for PKCE)", text: $config.clientSecret)
            TextField("Redirect URI", text: $config.redirectURI)
            TextField("Scopes", text: $config.scopes)
            if showBaseURL {
                TextField("Base URL", text: $config.baseURL)
            }
        }
    }
}
