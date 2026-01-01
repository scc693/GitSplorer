import Foundation

struct RemoteAccountStore {
    private let key = "GitSplorer.RemoteAccounts"

    func load() -> [RemoteAccount] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([RemoteAccount].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ accounts: [RemoteAccount]) {
        do {
            let data = try JSONEncoder().encode(accounts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // TODO: surface error to UI
        }
    }
}
