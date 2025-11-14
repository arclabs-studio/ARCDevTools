import Foundation

/// API pública de ARCDevTools
@available(macOS 13.0, iOS 17.0, *)
public enum ARCDevTools {

    /// Versión del package
    public static let version = "1.0.0"

    /// Bundle del módulo para acceder a recursos
    public static var bundle: Bundle {
        Bundle.module
    }

    // MARK: - Rutas a Recursos

    /// Ruta al archivo swiftlint.yml
    public static var swiftlintConfig: URL? {
        bundle.url(forResource: "swiftlint", withExtension: "yml", subdirectory: "Resources/Configs")
    }

    /// Ruta al archivo swiftformat
    public static var swiftformatConfig: URL? {
        bundle.url(forResource: "swiftformat", withExtension: nil, subdirectory: "Resources/Configs")
    }

    /// Directorio de scripts
    public static var scriptsDirectory: URL? {
        bundle.url(forResource: "Scripts", withExtension: nil, subdirectory: "Resources")
    }

    /// Directorio de templates
    public static var templatesDirectory: URL? {
        bundle.url(forResource: "Templates", withExtension: nil, subdirectory: "Resources")
    }

    // MARK: - Utilidades

    /// Copia un archivo de recursos a un destino
    public static func copyResource(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default

        // Crear directorio padre si no existe
        let parentDir = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        // Copiar archivo
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    /// Hace ejecutable un archivo shell
    public static func makeExecutable(_ url: URL) throws {
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.path
        )
    }
}
