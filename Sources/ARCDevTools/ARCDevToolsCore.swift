//
//  ARCDevToolsCore.swift
//  ARCDevTools
//
//  Created by ARC Labs Studio on 11/12/2024.
//

import Foundation

/// Public API for ARCDevTools
@available(macOS 13.0, iOS 17.0, *)
public enum ARCDevTools {
    /// Package version
    public static let version = "1.0.0"

    /// Module bundle for accessing resources
    public static var bundle: Bundle {
        Bundle.module
    }

    // MARK: - Resource Paths

    /// Path to swiftlint.yml configuration file
    public static var swiftlintConfig: URL? {
        bundle.url(forResource: "swiftlint", withExtension: "yml", subdirectory: "Resources/Configs")
    }

    /// Path to swiftformat configuration file
    public static var swiftformatConfig: URL? {
        bundle.url(forResource: "swiftformat", withExtension: nil, subdirectory: "Resources/Configs")
    }

    /// Scripts directory
    public static var scriptsDirectory: URL? {
        bundle.url(forResource: "Scripts", withExtension: nil, subdirectory: "Resources")
    }

    /// Templates directory
    public static var templatesDirectory: URL? {
        bundle.url(forResource: "Templates", withExtension: nil, subdirectory: "Resources")
    }

    // MARK: - Utilities

    /// Copies a resource file to a destination
    public static func copyResource(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default

        // Create parent directory if it doesn't exist
        let parentDir = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Copy file
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    /// Makes a shell script file executable
    public static func makeExecutable(_ url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.path
        )
    }
}
