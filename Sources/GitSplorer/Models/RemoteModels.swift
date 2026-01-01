import Foundation

enum RemoteProviderKind: String, Codable, CaseIterable {
    case github
    case gitlab
}

struct RemoteProviderConfiguration: Codable, Hashable {
    var clientId: String
    var clientSecret: String
    var redirectURI: String
    var scopes: String
    var baseURL: String

    static func defaults(for kind: RemoteProviderKind) -> RemoteProviderConfiguration {
        switch kind {
        case .github:
            return RemoteProviderConfiguration(
                clientId: "",
                clientSecret: "",
                redirectURI: "gitsplorer://oauth",
                scopes: "repo read:user",
                baseURL: ""
            )
        case .gitlab:
            return RemoteProviderConfiguration(
                clientId: "",
                clientSecret: "",
                redirectURI: "gitsplorer://oauth",
                scopes: "read_api read_user",
                baseURL: "https://gitlab.com"
            )
        }
    }

    static var empty: RemoteProviderConfiguration {
        RemoteProviderConfiguration(clientId: "", clientSecret: "", redirectURI: "", scopes: "", baseURL: "")
    }
}

struct RemoteAccount: Identifiable, Hashable, Codable {
    let id: UUID
    let provider: RemoteProviderKind
    let username: String
    let tokenHint: String
    let webBaseURL: String
    let apiBaseURL: String

    init(id: UUID = UUID(), provider: RemoteProviderKind, username: String, tokenHint: String, webBaseURL: String, apiBaseURL: String) {
        self.id = id
        self.provider = provider
        self.username = username
        self.tokenHint = tokenHint
        self.webBaseURL = webBaseURL
        self.apiBaseURL = apiBaseURL
    }
}

struct OAuthToken: Codable, Hashable {
    let accessToken: String
    let tokenType: String
    let refreshToken: String?
    let expiresIn: Int?
    let createdAt: Int?
    let scope: String?

    var isExpired: Bool {
        guard let expiresIn, let createdAt else { return false }
        let expiry = TimeInterval(createdAt + expiresIn)
        return Date().timeIntervalSince1970 >= expiry
    }
}

struct RemoteRepository: Identifiable, Hashable {
    let id: String
    let name: String
    let fullName: String
    let description: String
    let webURL: String
    let httpCloneURL: String
    let sshCloneURL: String
    let isPrivate: Bool
    let provider: RemoteProviderKind
}
