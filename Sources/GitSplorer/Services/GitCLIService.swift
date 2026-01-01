import Foundation

struct GitCLIService: GitService {
    private let gitPath = "/usr/bin/git"

    func listBranches(repoURL: URL) async throws -> [GitBranch] {
        let output = try ProcessRunner.run(gitPath, ["-C", repoURL.path, "branch", "--format=%(HEAD)%(refname:short)"])
        guard !output.isEmpty else { return [] }
        return output.split(separator: "\n").map { line in
            let lineString = String(line)
            let isCurrent = lineString.first == "*"
            let name = isCurrent ? String(lineString.dropFirst()) : lineString
            return GitBranch(name: name.trimmingCharacters(in: .whitespacesAndNewlines), isCurrent: isCurrent)
        }
    }

    func listRecentCommits(repoURL: URL, limit: Int) async throws -> [GitCommit] {
        let format = "%H%x1f%h%x1f%an%x1f%ad%x1f%s"
        let output = try ProcessRunner.run(gitPath, ["-C", repoURL.path, "log", "--date=iso", "--pretty=format:\(format)", "-n", "\(limit)"])
        guard !output.isEmpty else { return [] }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return output.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\u{1f}", omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 5 else { return nil }
            let date = formatter.date(from: parts[3]) ?? Date()
            return GitCommit(id: parts[0], message: parts[4], author: parts[2], date: date, shortHash: parts[1])
        }
    }

    func status(repoURL: URL) async throws -> [GitStatusEntry] {
        let output = try ProcessRunner.run(gitPath, ["-C", repoURL.path, "status", "--porcelain"])
        guard !output.isEmpty else { return [] }
        return output.split(separator: "\n").map { line in
            let lineString = String(line)
            let status = String(lineString.prefix(2)).trimmingCharacters(in: .whitespaces)
            let path = lineString.dropFirst(3)
            return GitStatusEntry(path: String(path), status: status)
        }
    }

    func readFile(repoURL: URL, path: String) async throws -> String {
        let fileURL = repoURL.appendingPathComponent(path)
        return try String(contentsOf: fileURL)
    }

    func cloneRepository(from remoteURL: String, to destinationURL: URL) async throws {
        _ = try ProcessRunner.run(gitPath, ["clone", remoteURL, destinationURL.path])
    }
}
