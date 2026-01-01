import Foundation

struct GitBranch: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isCurrent: Bool
}

struct GitCommit: Identifiable, Hashable {
    let id: String
    let message: String
    let author: String
    let date: Date
    let shortHash: String
}

struct GitStatusEntry: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let status: String
}

struct GitRemote: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: String
}

struct GitFileNode: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [GitFileNode]? = nil
}
