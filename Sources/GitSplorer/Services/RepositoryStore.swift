import Foundation

final class RepositoryStore {
    private let key = "GitSplorer.Repositories"
    private let defaults = UserDefaults.standard

    func load() -> [RepositoryLocation] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([RepositoryLocation].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ repositories: [RepositoryLocation]) {
        do {
            let data = try JSONEncoder().encode(repositories)
            defaults.set(data, forKey: key)
        } catch {
            // TODO: surface error to UI
        }
    }
}
