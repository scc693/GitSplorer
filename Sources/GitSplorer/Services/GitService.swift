import Foundation

protocol GitService: Sendable {
    func listBranches(repoURL: URL) async throws -> [GitBranch]
    func listRecentCommits(repoURL: URL, limit: Int) async throws -> [GitCommit]
    func status(repoURL: URL) async throws -> [GitStatusEntry]
    func readFile(repoURL: URL, path: String) async throws -> String
    func cloneRepository(from remoteURL: String, to destinationURL: URL) async throws
}
