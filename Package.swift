// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARCDevTools",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "ARCDevTools",
            targets: ["ARCDevTools"]
        ),
    ],
    targets: [
        .target(
            name: "ARCDevTools",
            path: "Sources"
        ),
        .testTarget(
            name: "ARCDevToolsTests",
            dependencies: ["ARCDevTools"],
            path: "Tests"
        )
    ]
)
