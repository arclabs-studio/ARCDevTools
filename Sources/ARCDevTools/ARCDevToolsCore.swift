//
//  ARCDevToolsCore.swift
//  ARCDevTools
//
//  Created by ARC Labs Studio on 11/12/2025.
//

import Foundation

/// Public API for ARCDevTools quality automation package.
///
/// ARCDevTools provides centralized access to SwiftLint configurations, SwiftFormat rules,
/// and automation scripts for ARC Labs Studio projects.
///
/// ## Overview
///
/// Use ARCDevTools to access quality tooling resources programmatically:
///
/// ```swift
/// import ARCDevTools
///
/// // Access configuration files
/// if let swiftlintURL = ARCDevTools.swiftlintConfig {
///     try FileManager.default.copyItem(at: swiftlintURL, to: destination)
/// }
///
/// // Copy resources with automatic directory creation
/// try ARCDevTools.copyResource(from: source, to: destination)
///
/// // Make scripts executable
/// try ARCDevTools.makeExecutable(scriptURL)
/// ```
///
/// ## Topics
///
/// ### Version Information
///
/// - ``version``
/// - ``bundle``
///
/// ### Configuration Resources
///
/// - ``swiftlintConfig``
/// - ``swiftformatConfig``
/// - ``scriptsDirectory``
///
/// ### Utility Functions
///
/// - ``copyResource(from:to:)``
/// - ``makeExecutable(_:)``
@available(macOS 13.0, iOS 17.0, *)
public enum ARCDevTools {
    /// The current version of the ARCDevTools package.
    ///
    /// Use this to verify compatibility or display version information in tools.
    ///
    /// ```swift
    /// print("ARCDevTools version: \(ARCDevTools.version)")
    /// ```
    public static let version = "1.0.0"

    /// The module's resource bundle.
    ///
    /// Provides access to bundled resources including configurations and scripts.
    /// Most of the time you'll use the specific properties like ``swiftlintConfig``
    /// instead of accessing the bundle directly.
    public static var bundle: Bundle {
        Bundle.module
    }

    // MARK: - Resource Paths

    /// URL to the SwiftLint configuration file.
    ///
    /// Returns the path to the `.swiftlint.yml` file bundled with ARCDevTools.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// if let swiftlintURL = ARCDevTools.swiftlintConfig {
    ///     let destination = URL(fileURLWithPath: ".swiftlint.yml")
    ///     try ARCDevTools.copyResource(from: swiftlintURL, to: destination)
    /// }
    /// ```
    ///
    /// - Returns: URL to the SwiftLint configuration, or `nil` if not found.
    public static var swiftlintConfig: URL? {
        bundle.url(forResource: "swiftlint", withExtension: "yml", subdirectory: "Resources/Configs")
    }

    /// URL to the SwiftFormat configuration file.
    ///
    /// Returns the path to the `.swiftformat` file bundled with ARCDevTools.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// if let swiftformatURL = ARCDevTools.swiftformatConfig {
    ///     let destination = URL(fileURLWithPath: ".swiftformat")
    ///     try ARCDevTools.copyResource(from: swiftformatURL, to: destination)
    /// }
    /// ```
    ///
    /// - Returns: URL to the SwiftFormat configuration, or `nil` if not found.
    public static var swiftformatConfig: URL? {
        bundle.url(forResource: "swiftformat", withExtension: nil, subdirectory: "Resources/Configs")
    }

    /// URL to the scripts directory.
    ///
    /// Contains automation scripts including pre-commit hooks and other utilities.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// if let scriptsDir = ARCDevTools.scriptsDirectory {
    ///     let preCommit = scriptsDir.appendingPathComponent("pre-commit")
    ///     try ARCDevTools.copyResource(from: preCommit, to: hookDestination)
    ///     try ARCDevTools.makeExecutable(hookDestination)
    /// }
    /// ```
    ///
    /// - Returns: URL to the scripts directory, or `nil` if not found.
    public static var scriptsDirectory: URL? {
        bundle.url(forResource: "Scripts", withExtension: nil, subdirectory: "Resources")
    }

    // MARK: - Utilities

    /// Copies a resource file from source to destination.
    ///
    /// This utility function handles:
    /// - Creating parent directories if they don't exist
    /// - Removing existing files at the destination
    /// - Atomic file copy operation
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let source = ARCDevTools.swiftlintConfig!
    /// let destination = URL(fileURLWithPath: "/path/to/project/.swiftlint.yml")
    ///
    /// try ARCDevTools.copyResource(from: source, to: destination)
    /// print("✓ Configuration copied successfully")
    /// ```
    ///
    /// - Parameters:
    ///   - source: The source file URL to copy from.
    ///   - destination: The destination file URL to copy to.
    ///
    /// - Throws: File system errors if the copy operation fails.
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

    /// Makes a shell script file executable by setting appropriate permissions.
    ///
    /// Sets file permissions to `0o755` (rwxr-xr-x), allowing the owner to read, write,
    /// and execute, while others can read and execute.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let scriptURL = URL(fileURLWithPath: "/path/to/script.sh")
    /// try ARCDevTools.makeExecutable(scriptURL)
    /// print("✓ Script is now executable")
    /// ```
    ///
    /// - Parameter url: The URL of the file to make executable.
    ///
    /// - Throws: File system errors if setting permissions fails.
    public static func makeExecutable(_ url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.path
        )
    }
}
