testing rebase 
# GitSplorer

A native macOS Git file explorer focused on visual navigation of repositories, history, and remotes. This repo ships a SwiftUI app with a Git CLI-backed service layer and OAuth-based GitHub/GitLab connections.

## Build & Run (Swift Package)

Open the package in Xcode or run with SwiftPM:

```
swift build
swift run
```

> Note: SwiftUI apps run best inside Xcode because it automatically handles app bundles and entitlements.

## Remote OAuth Setup (GitHub/GitLab)

1. Create an OAuth app on GitHub and/or GitLab.
2. Set the redirect URI to `gitsplorer://oauth` (or your custom scheme).
3. Paste the client ID (and optional secret) into **Settings > GitHub/GitLab OAuth**.
4. Connect and open the **Remotes** tab to browse repositories.

If you change the redirect URI, be sure to update both the provider settings and the app configuration to register the URL scheme.

## What’s Included

- Repository sidebar with branch and status sections
- File tree explorer with inline preview
- Commit history view
- Git CLI integration (`/usr/bin/git`) for branches, history, and status
- OAuth for GitHub/GitLab with remote repo browser and clone actions
- Settings for provider configuration and connected accounts

## Roadmap (next milestones)

- App bundle, entitlements, and proper window commands
- Rich file diff, blame, and commit details
- Stash, stage/unstage, and branch actions
- Token refresh and multi-account management
- Performance improvements for large repos
- Spotlight-style quick open

## Project Structure

```
Sources/GitSplorer/
  App/              SwiftUI App entry + state
  Models/           Repository, commit, file tree models
  Services/         Git CLI adapter, file scanning, remotes
  UI/               Views for sidebar, tree, details, settings
  Utilities/        Process runner helpers
```
