import Foundation

struct FileSystemScanner: Sendable {
    private let ignoreNames: Set<String> = [".git", ".DS_Store"]

    func scan(rootURL: URL) async throws -> GitFileNode {
        return try buildNode(for: rootURL, fileManager: FileManager())
    }

    private func buildNode(for url: URL, fileManager: FileManager) throws -> GitFileNode {
        let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
        let isDirectory = resourceValues.isDirectory ?? false
        var node = GitFileNode(url: url, name: url.lastPathComponent, isDirectory: isDirectory)

        guard isDirectory else { return node }
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        let filtered = contents.filter { !ignoreNames.contains($0.lastPathComponent) }
        let children = try filtered.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }.map { try buildNode(for: $0, fileManager: fileManager) }
        node.children = children.isEmpty ? nil : children
        return node
    }
}
