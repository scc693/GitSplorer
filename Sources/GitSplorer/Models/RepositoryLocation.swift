import Foundation

struct RepositoryLocation: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    let displayName: String
}
