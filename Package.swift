// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitSplorer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "GitSplorer", targets: ["GitSplorer"])
    ],
    targets: [
        .executableTarget(
            name: "GitSplorer"
        )
    ]
)
