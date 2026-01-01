import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: DetailTab = .file

    var body: some View {
        VStack(spacing: 0) {
            if appState.selectedRepository == nil {
                EmptyStateView()
            } else {
                Picker("Detail", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                switch selectedTab {
                case .file:
                    FileDetailView()
                case .history:
                    CommitHistoryView()
                case .status:
                    StatusView()
                case .remotes:
                    RemoteExplorerView()
                }
            }
        }
        .onChange(of: appState.selectedFile) { _ in
            Task { await appState.loadSelectedFileContent() }
        }
    }
}

private enum DetailTab: CaseIterable {
    case file
    case history
    case status
    case remotes

    var title: String {
        switch self {
        case .file: return "File"
        case .history: return "History"
        case .status: return "Status"
        case .remotes: return "Remotes"
        }
    }
}
