import SwiftUI
import AppKit

struct FileTreeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let root = appState.fileTree {
                List(selection: $appState.selectedFile) {
                    OutlineGroup(root, children: \.children) { node in
                        HStack {
                            Image(systemName: node.isDirectory ? "folder.fill" : "doc.text")
                            Text(node.name)
                        }
                        .tag(node)
                        .contextMenu {
                            Button("Copy Path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(node.url.path, forType: .string)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 42))
                    Text("Select a repository to view files")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if appState.isLoadingRepository {
                ProgressView("Loading repository…")
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
