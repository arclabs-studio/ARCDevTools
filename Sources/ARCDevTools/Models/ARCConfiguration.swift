import Foundation

/// Configuración centralizada de estándares ARC Labs
public struct ARCConfiguration: Codable, Sendable {

    // MARK: - Lint Rules

    public struct LintRules: Codable, Sendable {
        public var warningThreshold: Int
        public var errorThreshold: Int
        public var typBodyLengthWarning: Int
        public var typBodyLengthError: Int

        public static let `default` = LintRules(
            warningThreshold: 10,
            errorThreshold: 50,
            typBodyLengthWarning: 300,
            typBodyLengthError: 500
        )
    }

    // MARK: - Format Rules

    public struct FormatRules: Codable, Sendable {
        public var indent: Int
        public var maxWidth: Int
        public var lineBreaks: String

        public static let `default` = FormatRules(
            indent: 4,
            maxWidth: 120,
            lineBreaks: "lf"
        )
    }

    // MARK: - Properties

    public var lintRules: LintRules
    public var formatRules: FormatRules
    public var enablePreCommitHooks: Bool
    public var autoFormat: Bool

    // MARK: - Default Configuration

    public static let `default` = ARCConfiguration(
        lintRules: .default,
        formatRules: .default,
        enablePreCommitHooks: true,
        autoFormat: true
    )

    // MARK: - Persistence

    /// Carga configuración desde archivo o usa default
    public static func load(from url: URL) -> ARCConfiguration {
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(ARCConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    /// Guarda configuración a disco
    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }
}
