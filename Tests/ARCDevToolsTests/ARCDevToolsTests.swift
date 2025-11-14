import XCTest
@testable import ARCDevTools

final class ARCDevToolsTests: XCTestCase {

    // MARK: - Version Tests

    func testVersion() {
        XCTAssertEqual(ARCDevTools.version, "1.0.0")
    }

    // MARK: - Bundle Tests

    func testBundleExists() {
        let bundle = ARCDevTools.bundle
        XCTAssertNotNil(bundle)
    }

    // MARK: - Config Resources Tests

    func testSwiftLintConfigExists() {
        let config = ARCDevTools.swiftlintConfig
        XCTAssertNotNil(config, "SwiftLint config should exist")

        if let url = config {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "SwiftLint config file should exist at path")
        }
    }

    func testSwiftFormatConfigExists() {
        let config = ARCDevTools.swiftformatConfig
        XCTAssertNotNil(config, "SwiftFormat config should exist")

        if let url = config {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "SwiftFormat config file should exist at path")
        }
    }

    // MARK: - Scripts Directory Tests

    func testScriptsDirectoryExists() {
        let scriptsDir = ARCDevTools.scriptsDirectory
        XCTAssertNotNil(scriptsDir, "Scripts directory should exist")

        if let url = scriptsDir {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            XCTAssertTrue(exists, "Scripts directory should exist at path")
            XCTAssertTrue(isDirectory.boolValue, "Scripts path should be a directory")
        }
    }

    // MARK: - Templates Directory Tests

    func testTemplatesDirectoryExists() {
        let templatesDir = ARCDevTools.templatesDirectory
        XCTAssertNotNil(templatesDir, "Templates directory should exist")

        if let url = templatesDir {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            XCTAssertTrue(exists, "Templates directory should exist at path")
            XCTAssertTrue(isDirectory.boolValue, "Templates path should be a directory")
        }
    }

    // MARK: - Utilities Tests

    func testCopyResourceCreatesDestination() throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.txt")
        let destination = tempDir.appendingPathComponent("copied.txt")

        // Create source file
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)

        // When
        try ARCDevTools.copyResource(from: testFile, to: destination)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))

        let content = try String(contentsOf: destination)
        XCTAssertEqual(content, "Test content")

        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: destination)
    }

    func testMakeExecutable() throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let scriptFile = tempDir.appendingPathComponent("script.sh")

        // Create script file
        try "#!/bin/bash\necho test".write(to: scriptFile, atomically: true, encoding: .utf8)

        // When
        try ARCDevTools.makeExecutable(scriptFile)

        // Then
        let attributes = try FileManager.default.attributesOfItem(atPath: scriptFile.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertNotNil(permissions)
        XCTAssertEqual(permissions?.uint16Value, 0o755)

        // Cleanup
        try? FileManager.default.removeItem(at: scriptFile)
    }

    // MARK: - Configuration Tests

    func testDefaultConfiguration() {
        let config = ARCConfiguration.default

        XCTAssertEqual(config.lintRules.warningThreshold, 10)
        XCTAssertEqual(config.lintRules.errorThreshold, 50)
        XCTAssertEqual(config.formatRules.indent, 4)
        XCTAssertEqual(config.formatRules.maxWidth, 120)
        XCTAssertTrue(config.enablePreCommitHooks)
        XCTAssertTrue(config.autoFormat)
    }

    func testConfigurationPersistence() throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let configFile = tempDir.appendingPathComponent("test-config.json")
        let config = ARCConfiguration.default

        // When
        try config.save(to: configFile)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: configFile.path))

        let loadedConfig = ARCConfiguration.load(from: configFile)
        XCTAssertEqual(loadedConfig.lintRules.warningThreshold, config.lintRules.warningThreshold)
        XCTAssertEqual(loadedConfig.formatRules.indent, config.formatRules.indent)

        // Cleanup
        try? FileManager.default.removeItem(at: configFile)
    }
}
