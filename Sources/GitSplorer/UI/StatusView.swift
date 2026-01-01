import SwiftUI

struct StatusView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.statusEntries.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 42))
                Text("Working tree clean")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(appState.statusEntries) { entry in
                HStack {
                    Text(entry.path)
                    Spacer()
                    Text(entry.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
