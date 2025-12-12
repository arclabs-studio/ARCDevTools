//
//  ARCConfiguration.swift
//  ARCDevTools
//
//  Created by ARC Labs Studio on 11/12/2025.
//

import Foundation

/// Centralized configuration model for ARC Labs development standards.
///
/// Use `ARCConfiguration` to manage linting rules, formatting preferences, and automation
/// settings programmatically. The configuration can be saved to and loaded from JSON files.
///
/// ## Overview
///
/// ```swift
/// // Use default configuration
/// let config = ARCConfiguration.default
/// print("Indent: \(config.formatRules.indent)")
/// print("Pre-commit hooks enabled: \(config.enablePreCommitHooks)")
///
/// // Create custom configuration
/// var customConfig = ARCConfiguration.default
/// customConfig.formatRules.indent = 2
/// customConfig.lintRules.warningThreshold = 20
///
/// // Save and load
/// try customConfig.save(to: URL(fileURLWithPath: "config.json"))
/// let loaded = ARCConfiguration.load(from: URL(fileURLWithPath: "config.json"))
/// ```
///
/// ## Topics
///
/// ### Configuration Sections
///
/// - ``LintRules``
/// - ``FormatRules``
///
/// ### Properties
///
/// - ``lintRules``
/// - ``formatRules``
/// - ``enablePreCommitHooks``
/// - ``autoFormat``
///
/// ### Persistence
///
/// - ``load(from:)``
/// - ``save(to:)``
public struct ARCConfiguration: Codable, Sendable {
    // MARK: - Lint Rules

    /// SwiftLint configuration rules.
    ///
    /// Defines thresholds for linting warnings and errors, as well as type body length limits.
    ///
    /// ```swift
    /// var lintRules = ARCConfiguration.LintRules.default
    /// lintRules.warningThreshold = 20  // Allow more warnings
    /// lintRules.errorThreshold = 100   // Stricter error threshold
    /// ```
    public struct LintRules: Codable, Sendable {
        /// Maximum number of warnings before build fails
        public var warningThreshold: Int

        /// Maximum number of errors before build fails
        public var errorThreshold: Int

        /// Warning threshold for type body length
        public var typBodyLengthWarning: Int

        /// Error threshold for type body length
        public var typBodyLengthError: Int

        /// Default lint rules configuration
        public static let `default` = LintRules(
            warningThreshold: 10,
            errorThreshold: 50,
            typBodyLengthWarning: 300,
            typBodyLengthError: 500
        )
    }

    // MARK: - Format Rules

    /// SwiftFormat configuration rules.
    ///
    /// Defines formatting preferences including indentation, line width, and line breaks.
    ///
    /// ```swift
    /// var formatRules = ARCConfiguration.FormatRules.default
    /// formatRules.indent = 2      // Use 2-space indentation
    /// formatRules.maxWidth = 100  // Shorter line width
    /// ```
    public struct FormatRules: Codable, Sendable {
        /// Number of spaces for indentation
        public var indent: Int

        /// Maximum line width before wrapping
        public var maxWidth: Int

        /// Line break style ("lf", "cr", or "crlf")
        public var lineBreaks: String

        /// Default format rules configuration
        public static let `default` = FormatRules(
            indent: 4,
            maxWidth: 120,
            lineBreaks: "lf"
        )
    }

    // MARK: - Properties

    /// SwiftLint rules configuration
    public var lintRules: LintRules

    /// SwiftFormat rules configuration
    public var formatRules: FormatRules

    /// Whether to enable pre-commit git hooks
    public var enablePreCommitHooks: Bool

    /// Whether to automatically format code on save/commit
    public var autoFormat: Bool

    // MARK: - Default Configuration

    /// Default ARCDevTools configuration.
    ///
    /// Provides standard settings aligned with ARC Labs development standards:
    /// - 4-space indentation
    /// - 120-character line width
    /// - LF line breaks
    /// - Pre-commit hooks enabled
    /// - Auto-formatting enabled
    public static let `default` = ARCConfiguration(
        lintRules: .default,
        formatRules: .default,
        enablePreCommitHooks: true,
        autoFormat: true
    )

    // MARK: - Persistence

    /// Loads configuration from a JSON file.
    ///
    /// If the file doesn't exist or can't be decoded, returns the default configuration.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let configURL = URL(fileURLWithPath: ".arc-config.json")
    /// let config = ARCConfiguration.load(from: configURL)
    ///
    /// print("Loaded indent setting: \(config.formatRules.indent)")
    /// ```
    ///
    /// - Parameter url: The URL of the JSON configuration file.
    /// - Returns: The loaded configuration, or default if loading fails.
    public static func load(from url: URL) -> ARCConfiguration {
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(ARCConfiguration.self, from: data)
        else {
            return .default
        }
        return config
    }

    /// Saves configuration to a JSON file.
    ///
    /// The configuration is encoded as JSON and written to the specified file URL.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// var config = ARCConfiguration.default
    /// config.formatRules.indent = 2
    ///
    /// let configURL = URL(fileURLWithPath: ".arc-config.json")
    /// try config.save(to: configURL)
    /// print("✓ Configuration saved")
    /// ```
    ///
    /// - Parameter url: The destination URL for the JSON file.
    /// - Throws: Encoding or file system errors.
    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
}
