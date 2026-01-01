# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

### Swift Package Manager
```bash
swift build                    # Build the project
swift run                      # Run the app
```

### Xcode
Open `GitSplorer.xcodeproj` in Xcode and build/run from there. SwiftUI apps run best inside Xcode because it handles app bundles and entitlements automatically.

### XcodeGen
If you modify `project.yml`:
```bash
xcodegen generate             # Regenerate Xcode project from project.yml
```

## Architecture Overview

### Core Architecture Pattern
The app follows a centralized state management pattern with SwiftUI:
- **AppState** (`App/AppState.swift`): `@MainActor` `ObservableObject` that holds all application state and coordinates between services
- **Services**: Protocol-based services injected into AppState
- **Models**: Simple value types for Git and remote provider data
- **UI**: SwiftUI views that observe AppState via `@EnvironmentObject`

### Key Services & Their Roles

**GitService** (`Services/GitService.swift`)
- Protocol for Git operations (branches, commits, status, file reading, cloning)
- **GitCLIService** (`Services/GitCLIService.swift`): Implementation that shells out to `/usr/bin/git` using ProcessRunner
- All Git operations are async and may throw

**RemoteProvider** (`Services/RemoteProviders.swift`)
- Protocol for remote Git hosting providers (GitHub, GitLab)
- Handles OAuth authentication flow with PKCE
- API calls for listing repositories
- **GitHubProvider** and **GitLabProvider**: Concrete implementations

**Storage Services**
- **RepositoryStore**: Persists repository list to UserDefaults
- **RemoteAccountStore**: Persists connected accounts to UserDefaults
- **RemoteConfigurationStore**: Persists OAuth configs to UserDefaults
- **RemoteTokenStore** (`Services/RemoteTokenStore.swift`): Stores OAuth tokens in Keychain via KeychainStore
- **KeychainStore** (`Services/KeychainStore.swift`): Wrapper around macOS Keychain APIs

**FileSystemScanner** (`Services/FileSystemScanner.swift`)
- Recursively scans directories to build GitFileNode tree for file explorer

### Data Flow

1. User actions trigger AppState methods
2. AppState coordinates service calls (GitService, RemoteProviders, etc.)
3. Services perform operations and return results
4. AppState updates `@Published` properties
5. SwiftUI views automatically re-render

Example: Loading a repository
```
User selects repo → AppState.refreshSelection() →
  FileSystemScanner.scan() + GitCLIService.listBranches/listRecentCommits/status() →
  AppState updates @Published properties → Views re-render
```

### OAuth Flow

OAuth authentication uses `ASWebAuthenticationSession` wrapped in `OAuthWebSession`:
1. AppState.connectRemote() called with provider (GitHub/GitLab)
2. Provider generates PKCE challenge and state
3. Opens browser to provider's OAuth authorize endpoint
4. User approves, browser redirects to `gitsplorer://oauth` with code
5. Provider exchanges code for access token
6. Provider fetches user info and creates RemoteAccount
7. Token stored in Keychain, account stored in UserDefaults

### Process Execution

All external process calls (git commands) use **ProcessRunner** (`Utilities/ProcessRunner.swift`):
- Synchronous wrapper around Foundation.Process
- Captures stdout/stderr
- Throws `ProcessRunnerError.nonZeroExit` on failure
- Used exclusively by GitCLIService

## Important Patterns

### Error Handling
- Services throw errors; AppState catches them and updates UI state (e.g., `remoteErrorMessage`)
- Git CLI errors include stderr output in the error message
- No global error handling; errors are contextual to the operation

### Concurrency
- AppState is `@MainActor` - all methods run on main thread
- Service calls are async but don't enforce actors (GitCLIService uses ProcessRunner which is synchronous)
- RemoteProvider protocol has `@MainActor` on `connect()` only (for ASWebAuthenticationSession)

### Testing
Currently no test target exists in the project.

## OAuth Configuration

To enable remote repository browsing:
1. Create OAuth app on GitHub/GitLab with redirect URI: `gitsplorer://oauth`
2. In app Settings, paste client ID (and optional secret) for the provider
3. Connect account via Settings and browse remotes

Default scopes:
- **GitHub**: `repo read:user`
- **GitLab**: `read_api read_user`

## File Organization

```
Sources/GitSplorer/
  App/                    # App entry point and centralized state
    GitSplorerApp.swift   # @main SwiftUI App
    AppState.swift        # Central ObservableObject coordinator

  Models/                 # Data models
    GitModels.swift       # GitBranch, GitCommit, GitStatusEntry, GitFileNode
    RemoteModels.swift    # RemoteAccount, OAuthToken, RemoteRepository, etc.
    RepositoryLocation.swift

  Services/               # Business logic and external integrations
    GitService.swift      # Protocol for Git operations
    GitCLIService.swift   # Git CLI implementation
    RemoteProviders.swift # GitHub/GitLab OAuth and API clients
    FileSystemScanner.swift
    *Store.swift          # Persistence (UserDefaults/Keychain)

  UI/                     # SwiftUI views
    ContentView.swift     # Main app layout
    SidebarView.swift     # Repository + branch sidebar
    FileTreeView.swift    # File explorer
    CommitHistoryView.swift
    StatusView.swift
    RemoteExplorerView.swift
    SettingsView.swift
    DetailView.swift
    FileDetailView.swift
    EmptyStateView.swift

  Utilities/              # Low-level helpers
    ProcessRunner.swift   # Process execution wrapper
    OAuth.swift           # PKCE generation, ASWebAuthenticationSession
```

## Platform & Requirements

- **Platform**: macOS 13.0+
- **Swift**: 5.9+ (Swift 6.2 tools version)
- **Git**: Requires `/usr/bin/git` to be available
- **Bundle ID**: `com.example.GitSplorer`
