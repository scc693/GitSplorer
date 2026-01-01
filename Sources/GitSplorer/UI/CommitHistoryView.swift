import SwiftUI

struct CommitHistoryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List(appState.recentCommits) { commit in
            VStack(alignment: .leading, spacing: 6) {
                Text(commit.message)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(commit.shortHash)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(commit.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(commit.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
