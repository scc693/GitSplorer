import Foundation

struct RemoteConfigurationStore {
    private let key = "GitSplorer.RemoteConfigs"

    func load() -> [RemoteProviderKind: RemoteProviderConfiguration] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return [:]
        }
        do {
            return try JSONDecoder().decode([RemoteProviderKind: RemoteProviderConfiguration].self, from: data)
        } catch {
            return [:]
        }
    }

    func save(_ configs: [RemoteProviderKind: RemoteProviderConfiguration]) {
        do {
            let data = try JSONEncoder().encode(configs)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // TODO: surface error to UI
        }
    }
}
