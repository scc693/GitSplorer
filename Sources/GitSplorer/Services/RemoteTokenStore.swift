import Foundation

struct RemoteTokenStore {
    private let keychain = KeychainStore()
    private let service = "GitSplorer.RemoteTokens"

    func token(for account: RemoteAccount) -> OAuthToken? {
        let key = tokenKey(for: account)
        do {
            guard let data = try keychain.read(service: service, account: key) else { return nil }
            return try JSONDecoder().decode(OAuthToken.self, from: data)
        } catch {
            return nil
        }
    }

    func save(_ token: OAuthToken, for account: RemoteAccount) {
        let key = tokenKey(for: account)
        do {
            let data = try JSONEncoder().encode(token)
            try keychain.save(data, service: service, account: key)
        } catch {
            // TODO: surface error to UI
        }
    }

    func deleteToken(for account: RemoteAccount) {
        let key = tokenKey(for: account)
        do {
            try keychain.delete(service: service, account: key)
        } catch {
            // TODO: surface error to UI
        }
    }

    private func tokenKey(for account: RemoteAccount) -> String {
        "\(account.provider.rawValue)|\(account.username)"
    }
}
