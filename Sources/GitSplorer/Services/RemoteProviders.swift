import Foundation

protocol RemoteProvider: Sendable {
    var kind: RemoteProviderKind { get }
    var displayName: String { get }
    @MainActor func connect(using config: RemoteProviderConfiguration, webSession: OAuthWebSession) async throws -> RemoteConnection
    func listRepositories(account: RemoteAccount, token: OAuthToken) async throws -> [RemoteRepository]
}

struct RemoteConnection {
    let account: RemoteAccount
    let token: OAuthToken
}

enum RemoteProviderError: Error {
    case missingConfiguration
    case invalidRedirectURI
    case missingCode
    case missingState
    case stateMismatch
    case invalidResponse
}

struct RemoteAPIError: Error {
    let statusCode: Int
    let message: String
}

struct RemoteAPIClient {
    let baseURL: URL

    func get(path: String, token: OAuthToken) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        return try await execute(request)
    }

    func postForm(url: URL, parameters: [String: String], headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = parameters
            .map { key, value in "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        return try await execute(request)
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw RemoteProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(decoding: data, as: UTF8.self)
            throw RemoteAPIError(statusCode: http.statusCode, message: message)
        }
        return data
    }
}

struct GitHubProvider: RemoteProvider {
    let kind: RemoteProviderKind = .github
    let displayName = "GitHub"

    func connect(using config: RemoteProviderConfiguration, webSession: OAuthWebSession) async throws -> RemoteConnection {
        guard !config.clientId.isEmpty else { throw RemoteProviderError.missingConfiguration }
        guard let redirectURL = URL(string: config.redirectURI), let scheme = redirectURL.scheme else {
            throw RemoteProviderError.invalidRedirectURI
        }

        let pkce = OAuthHelpers.generatePKCE()
        let state = OAuthHelpers.randomString(length: 24)

        var components = URLComponents(string: "https://github.com/login/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let authURL = components?.url else { throw RemoteProviderError.invalidResponse }

        let callbackURL = try await webSession.authenticate(authURL: authURL, callbackScheme: scheme)
        let items = OAuthHelpers.queryItems(from: callbackURL)
        guard let code = items.first(where: { $0.name == "code" })?.value else { throw RemoteProviderError.missingCode }
        guard let returnedState = items.first(where: { $0.name == "state" })?.value else { throw RemoteProviderError.missingState }
        guard returnedState == state else { throw RemoteProviderError.stateMismatch }

        guard let tokenURL = URL(string: "https://github.com/login/oauth/access_token"),
              let apiBaseURL = URL(string: "https://api.github.com") else {
            throw RemoteProviderError.invalidResponse
        }
        var params: [String: String] = [
            "client_id": config.clientId,
            "code": code,
            "redirect_uri": config.redirectURI,
            "code_verifier": pkce.verifier
        ]
        if !config.clientSecret.isEmpty {
            params["client_secret"] = config.clientSecret
        }
        let api = RemoteAPIClient(baseURL: apiBaseURL)
        let data = try await api.postForm(url: tokenURL, parameters: params, headers: ["Accept": "application/json"])
        let response = try JSONDecoder().decode(GitHubTokenResponse.self, from: data)
        let token = OAuthToken(accessToken: response.access_token, tokenType: response.token_type, refreshToken: nil, expiresIn: nil, createdAt: nil, scope: response.scope)

        let userData = try await api.get(path: "user", token: token)
        let user = try JSONDecoder().decode(GitHubUser.self, from: userData)

        let account = RemoteAccount(
            provider: .github,
            username: user.login,
            tokenHint: String(response.access_token.suffix(4)),
            webBaseURL: "https://github.com",
            apiBaseURL: "https://api.github.com"
        )
        return RemoteConnection(account: account, token: token)
    }

    func listRepositories(account: RemoteAccount, token: OAuthToken) async throws -> [RemoteRepository] {
        guard let baseURL = URL(string: account.apiBaseURL) else {
            throw RemoteProviderError.invalidResponse
        }
        let api = RemoteAPIClient(baseURL: baseURL)
        let data = try await api.get(path: "user/repos?per_page=100&sort=updated", token: token)
        let repos = try JSONDecoder().decode([GitHubRepo].self, from: data)
        return repos.map {
            RemoteRepository(
                id: String($0.id),
                name: $0.name,
                fullName: $0.full_name,
                description: $0.description ?? "",
                webURL: $0.html_url,
                httpCloneURL: $0.clone_url,
                sshCloneURL: $0.ssh_url,
                isPrivate: $0.private,
                provider: .github
            )
        }
    }
}

struct GitLabProvider: RemoteProvider {
    let kind: RemoteProviderKind = .gitlab
    let displayName = "GitLab"

    func connect(using config: RemoteProviderConfiguration, webSession: OAuthWebSession) async throws -> RemoteConnection {
        guard !config.clientId.isEmpty else { throw RemoteProviderError.missingConfiguration }
        guard let redirectURL = URL(string: config.redirectURI), let scheme = redirectURL.scheme else {
            throw RemoteProviderError.invalidRedirectURI
        }
        let baseURL = normalizedBaseURL(config.baseURL.isEmpty ? "https://gitlab.com" : config.baseURL)

        let pkce = OAuthHelpers.generatePKCE()
        let state = OAuthHelpers.randomString(length: 24)

        var components = URLComponents(string: "\(baseURL)/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let authURL = components?.url else { throw RemoteProviderError.invalidResponse }

        let callbackURL = try await webSession.authenticate(authURL: authURL, callbackScheme: scheme)
        let items = OAuthHelpers.queryItems(from: callbackURL)
        guard let code = items.first(where: { $0.name == "code" })?.value else { throw RemoteProviderError.missingCode }
        guard let returnedState = items.first(where: { $0.name == "state" })?.value else { throw RemoteProviderError.missingState }
        guard returnedState == state else { throw RemoteProviderError.stateMismatch }

        guard let tokenURL = URL(string: "\(baseURL)/oauth/token"),
              let apiBaseURL = URL(string: "\(baseURL)/api/v4") else {
            throw RemoteProviderError.invalidResponse
        }
        var params: [String: String] = [
            "client_id": config.clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectURI,
            "code_verifier": pkce.verifier
        ]
        if !config.clientSecret.isEmpty {
            params["client_secret"] = config.clientSecret
        }

        let api = RemoteAPIClient(baseURL: apiBaseURL)
        let data = try await api.postForm(url: tokenURL, parameters: params)
        let response = try JSONDecoder().decode(GitLabTokenResponse.self, from: data)
        let token = OAuthToken(
            accessToken: response.access_token,
            tokenType: response.token_type,
            refreshToken: response.refresh_token,
            expiresIn: response.expires_in,
            createdAt: response.created_at,
            scope: response.scope
        )

        let userData = try await api.get(path: "user", token: token)
        let user = try JSONDecoder().decode(GitLabUser.self, from: userData)

        let account = RemoteAccount(
            provider: .gitlab,
            username: user.username,
            tokenHint: String(response.access_token.suffix(4)),
            webBaseURL: baseURL,
            apiBaseURL: "\(baseURL)/api/v4"
        )
        return RemoteConnection(account: account, token: token)
    }

    func listRepositories(account: RemoteAccount, token: OAuthToken) async throws -> [RemoteRepository] {
        guard let baseURL = URL(string: account.apiBaseURL) else {
            throw RemoteProviderError.invalidResponse
        }
        let api = RemoteAPIClient(baseURL: baseURL)
        let data = try await api.get(path: "projects?membership=true&per_page=100&order_by=last_activity_at", token: token)
        let repos = try JSONDecoder().decode([GitLabRepo].self, from: data)
        return repos.map {
            RemoteRepository(
                id: String($0.id),
                name: $0.name,
                fullName: $0.path_with_namespace,
                description: $0.description ?? "",
                webURL: $0.web_url,
                httpCloneURL: $0.http_url_to_repo,
                sshCloneURL: $0.ssh_url_to_repo,
                isPrivate: $0.visibility == "private",
                provider: .gitlab
            )
        }
    }

    private func normalizedBaseURL(_ value: String) -> String {
        value.hasSuffix("/") ? String(value.dropLast()) : value
    }
}

private struct GitHubTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let scope: String?
}

private struct GitHubUser: Decodable {
    let login: String
}

private struct GitHubRepo: Decodable {
    let id: Int
    let name: String
    let full_name: String
    let html_url: String
    let clone_url: String
    let ssh_url: String
    let description: String?
    let `private`: Bool
}

private struct GitLabTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let refresh_token: String?
    let expires_in: Int?
    let created_at: Int?
    let scope: String?
}

private struct GitLabUser: Decodable {
    let username: String
}

private struct GitLabRepo: Decodable {
    let id: Int
    let name: String
    let path_with_namespace: String
    let web_url: String
    let http_url_to_repo: String
    let ssh_url_to_repo: String
    let description: String?
    let visibility: String
}
