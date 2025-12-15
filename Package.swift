// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ARCDevTools",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        // Main library
        .library(
            name: "ARCDevTools",
            targets: ["ARCDevTools"]
        ),
        // Setup executable
        .executable(
            name: "arc-setup",
            targets: ["arc-setup"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/arclabs-studio/ARCAgentsDocs.git", from: "1.0.0"),
    ],
    targets: [
        // Main target
        .target(
            name: "ARCDevTools",
            dependencies: [],
            resources: [
                .copy("Resources")
            ]
        ),

        // Setup executable target
        .executableTarget(
            name: "arc-setup",
            dependencies: ["ARCDevTools"]
        ),

        // Tests
        .testTarget(
            name: "ARCDevToolsTests",
            dependencies: ["ARCDevTools"]
        )
    ],
    swiftLanguageModes: [.v6]
)
