import Foundation
import ARCDevTools

@main
struct ARCSetup {
    static func main() async throws {
        print("🔧 ARCDevTools Setup v\(ARCDevTools.version)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        let fileManager = FileManager.default
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        // 1. Verificar que estamos en raíz de proyecto
        guard fileManager.fileExists(atPath: currentDir.appendingPathComponent("Package.swift").path) ||
              fileManager.fileExists(atPath: currentDir.appendingPathComponent(".xcodeproj").pathExtension.isEmpty == false) else {
            print("❌ Error: Ejecuta este comando desde la raíz de tu proyecto")
            throw ExitCode.failure
        }

        // 2. Copiar configs
        try setupConfigs(to: currentDir)

        // 3. Instalar git hooks
        try setupGitHooks(to: currentDir)

        // 4. Generar Makefile
        try generateMakefile(to: currentDir)

        // 5. Crear directorio de templates (opcional)
        try setupTemplates(to: currentDir)

        print("\n✅ ARCDevTools configurado correctamente")
        print("\n📝 Próximos pasos:")
        print("   1. Ejecuta: make lint")
        print("   2. Ejecuta: make format")
        print("   3. Haz commit para probar pre-commit hook")
        print("\n💡 Ver comandos disponibles: make help")
    }

    // MARK: - Setup Functions

    static func setupConfigs(to projectDir: URL) throws {
        print("\n📦 Copiando configuraciones...")

        // SwiftLint
        if let swiftlintSource = ARCDevTools.swiftlintConfig {
            let dest = projectDir.appendingPathComponent(".swiftlint.yml")
            try ARCDevTools.copyResource(from: swiftlintSource, to: dest)
            print("   ✓ .swiftlint.yml")
        }

        // SwiftFormat
        if let swiftformatSource = ARCDevTools.swiftformatConfig {
            let dest = projectDir.appendingPathComponent(".swiftformat")
            try ARCDevTools.copyResource(from: swiftformatSource, to: dest)
            print("   ✓ .swiftformat")
        }
    }

    static func setupGitHooks(to projectDir: URL) throws {
        print("\n🪝 Instalando git hooks...")

        let gitHooksDir = projectDir.appendingPathComponent(".git/hooks")

        guard FileManager.default.fileExists(atPath: gitHooksDir.path) else {
            print("   ⚠️  No se encontró .git/hooks (¿es un repo git?)")
            return
        }

        guard let scriptsDir = ARCDevTools.scriptsDirectory,
              let preCommitSource = Bundle.module.url(
                forResource: "pre-commit",
                withExtension: nil,
                subdirectory: "Resources/Scripts"
              ) else {
            print("   ❌ No se encontraron scripts en el package")
            return
        }

        let preCommitDest = gitHooksDir.appendingPathComponent("pre-commit")
        try ARCDevTools.copyResource(from: preCommitSource, to: preCommitDest)
        try ARCDevTools.makeExecutable(preCommitDest)

        print("   ✓ pre-commit hook instalado")
    }

    static func generateMakefile(to projectDir: URL) throws {
        print("\n📄 Generando Makefile...")

        let makefileContent = """
# ARCDevTools Makefile
# Generado automáticamente - No editar manualmente

.PHONY: help lint format fix setup clean

help:
\t@echo "ARCDevTools - Comandos disponibles:"
\t@echo "  make lint      - Ejecutar SwiftLint"
\t@echo "  make format    - Ejecutar SwiftFormat (dry-run)"
\t@echo "  make fix       - Aplicar SwiftFormat"
\t@echo "  make setup     - Re-instalar hooks y configs"
\t@echo "  make clean     - Limpiar build artifacts"

lint:
\t@if command -v swiftlint >/dev/null 2>&1; then \\
\t\tswiftlint lint --config .swiftlint.yml; \\
\telse \\
\t\techo "⚠️  SwiftLint no instalado: brew install swiftlint"; \\
\tfi

format:
\t@if command -v swiftformat >/dev/null 2>&1; then \\
\t\tswiftformat --config .swiftformat --lint .; \\
\telse \\
\t\techo "⚠️  SwiftFormat no instalado: brew install swiftformat"; \\
\tfi

fix:
\t@if command -v swiftformat >/dev/null 2>&1; then \\
\t\tswiftformat --config .swiftformat .; \\
\telse \\
\t\techo "⚠️  SwiftFormat no instalado: brew install swiftformat"; \\
\tfi

setup:
\t@swift run arc-setup

clean:
\t@rm -rf .build DerivedData
\t@echo "✓ Build artifacts eliminados"

"""

        let makefileDest = projectDir.appendingPathComponent("Makefile")
        try makefileContent.write(to: makefileDest, atomically: true, encoding: .utf8)

        print("   ✓ Makefile generado")
    }

    static func setupTemplates(to projectDir: URL) throws {
        print("\n📋 Configurando templates...")

        let templatesDir = projectDir.appendingPathComponent("ARCTemplates")

        if FileManager.default.fileExists(atPath: templatesDir.path) {
            print("   ⚠️  ARCTemplates/ ya existe, omitiendo...")
            return
        }

        guard let source = ARCDevTools.templatesDirectory else {
            print("   ❌ No se encontraron templates")
            return
        }

        try FileManager.default.copyItem(at: source, to: templatesDir)
        print("   ✓ Templates copiados a ARCTemplates/")
    }
}

// MARK: - Error Handling

enum ExitCode: Error {
    case failure
}
