import Foundation
import Combine
import AppKit

@MainActor
final class AppState: ObservableObject {
    @Published var repositories: [RepositoryLocation] = []
    @Published var selectedRepository: RepositoryLocation? = nil
    @Published var fileTree: GitFileNode? = nil
    @Published var recentCommits: [GitCommit] = []
    @Published var branches: [GitBranch] = []
    @Published var statusEntries: [GitStatusEntry] = []
    @Published var selectedFile: GitFileNode? = nil
    @Published var selectedFileContent: String = ""
    @Published var isLoadingRepository: Bool = false
    @Published var remoteAccounts: [RemoteAccount] = []
    @Published var remoteRepositories: [RemoteRepository] = []
    @Published var selectedRemoteAccount: RemoteAccount? = nil
    @Published var remoteConfigs: [RemoteProviderKind: RemoteProviderConfiguration] = [:]
    @Published var remoteErrorMessage: String? = nil
    @Published var isLoadingRemote: Bool = false

    private let repoStore = RepositoryStore()
    private let remoteConfigStore = RemoteConfigurationStore()
    private let remoteAccountStore = RemoteAccountStore()
    private let remoteTokenStore = RemoteTokenStore()
    private let gitService: GitService
    private let fileScanner: FileSystemScanner
    private let webSession = OAuthWebSession()

    init(gitService: GitService = GitCLIService(), fileScanner: FileSystemScanner = FileSystemScanner()) {
        self.gitService = gitService
        self.fileScanner = fileScanner
        self.repositories = repoStore.load()
        self.selectedRepository = repositories.first
        self.remoteAccounts = remoteAccountStore.load()
        self.selectedRemoteAccount = remoteAccounts.first
        self.remoteConfigs = remoteConfigStore.load()
        Task { await refreshSelection() }
        Task { await refreshRemoteRepositories() }
    }

    func addRepository(url: URL) {
        let location = RepositoryLocation(id: UUID(), url: url, displayName: url.lastPathComponent)
        repositories.append(location)
        repoStore.save(repositories)
        selectedRepository = location
        Task { await refreshSelection() }
    }

    func removeRepositories(at offsets: IndexSet) {
        repositories.remove(atOffsets: offsets)
        repoStore.save(repositories)
        if let selected = selectedRepository, !repositories.contains(selected) {
            selectedRepository = repositories.first
        } else if selectedRepository == nil {
            selectedRepository = repositories.first
        }
        Task { await refreshSelection() }
    }

    func refreshSelection() async {
        guard let selectedRepository else {
            fileTree = nil
            branches = []
            recentCommits = []
            statusEntries = []
            selectedFile = nil
            selectedFileContent = ""
            return
        }
        isLoadingRepository = true
        defer { isLoadingRepository = false }

        do {
            let repoURL = selectedRepository.url
            self.fileTree = try await fileScanner.scan(rootURL: repoURL)
            self.branches = try await gitService.listBranches(repoURL: repoURL)
            self.recentCommits = try await gitService.listRecentCommits(repoURL: repoURL, limit: 50)
            self.statusEntries = try await gitService.status(repoURL: repoURL)
            self.selectedFile = nil
            self.selectedFileContent = ""
        } catch {
            self.fileTree = nil
            self.branches = []
            self.recentCommits = []
            self.statusEntries = []
            self.selectedFile = nil
            self.selectedFileContent = ""
        }
    }

    func loadSelectedFileContent() async {
        guard let selectedRepository, let selectedFile else { return }
        guard !selectedFile.isDirectory else { return }
        do {
            let relativePath = selectedFile.url.path.replacingOccurrences(of: selectedRepository.url.path + "/", with: "")
            let content = try await gitService.readFile(repoURL: selectedRepository.url, path: relativePath)
            selectedFileContent = content
        } catch {
            selectedFileContent = "Unable to load file content."
        }
    }

    func connectRemote(_ provider: RemoteProvider) async {
        remoteErrorMessage = nil
        do {
            let config = remoteConfigs[provider.kind] ?? .defaults(for: provider.kind)
            let connection = try await provider.connect(using: config, webSession: webSession)
            remoteAccounts.append(connection.account)
            remoteAccountStore.save(remoteAccounts)
            remoteTokenStore.save(connection.token, for: connection.account)
            selectedRemoteAccount = connection.account
            await refreshRemoteRepositories()
        } catch {
            remoteErrorMessage = String(describing: error)
        }
    }

    func refreshRemoteRepositories() async {
        remoteErrorMessage = nil
        guard let account = selectedRemoteAccount else {
            remoteRepositories = []
            return
        }
        guard let token = remoteTokenStore.token(for: account) else {
            remoteRepositories = []
            return
        }
        if token.isExpired {
            remoteRepositories = []
            remoteErrorMessage = "Remote access token expired. Reconnect to refresh."
            return
        }
        isLoadingRemote = true
        defer { isLoadingRemote = false }
        do {
            let provider: RemoteProvider = account.provider == .github ? GitHubProvider() : GitLabProvider()
            remoteRepositories = try await provider.listRepositories(account: account, token: token)
        } catch {
            remoteErrorMessage = String(describing: error)
        }
    }

    func saveRemoteConfig(_ config: RemoteProviderConfiguration, for kind: RemoteProviderKind) {
        remoteConfigs[kind] = config
        remoteConfigStore.save(remoteConfigs)
    }

    func clone(remote: RemoteRepository) async {
        guard let destination = pickCloneDestination(for: remote.name) else { return }
        do {
            try await gitService.cloneRepository(from: remote.httpCloneURL, to: destination)
            addRepository(url: destination)
        } catch {
            remoteErrorMessage = String(describing: error)
        }
    }

    private func pickCloneDestination(for name: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to clone into"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Clone"
        if panel.runModal() == .OK, let url = panel.url {
            return url.appendingPathComponent(name)
        }
        return nil
    }
}
