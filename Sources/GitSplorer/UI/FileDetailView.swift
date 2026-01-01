import SwiftUI

struct FileDetailView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let selectedFile = appState.selectedFile, !selectedFile.isDirectory {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedFile.url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(appState.selectedFileContent)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 42))
                    Text("Select a file to preview")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
