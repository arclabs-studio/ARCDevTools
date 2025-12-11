// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ARCDevTools",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        // Librería principal
        .library(
            name: "ARCDevTools",
            targets: ["ARCDevTools"]
        ),
        // Ejecutable para setup
        .executable(
            name: "arc-setup",
            targets: ["arc-setup"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/arclabs-studio/ARCAgentsDocs.git", from: "1.0.0"),
        // Stencil para templates (futuro)
        // .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.0")
    ],
    targets: [
        // Target principal
        .target(
            name: "ARCDevTools",
            dependencies: [],
            resources: [
                .copy("Resources")
            ]
        ),

        // Target ejecutable para setup
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
