//
//  ARCDevToolsTests.swift
//  ARCDevTools
//
//  Created by ARC Labs Studio on 11/12/2025.
//

import Foundation
import Testing
@testable import ARCDevTools

@Suite("ARCDevTools Core Tests")
struct ARCDevToolsTests {
    // MARK: Version Tests

    @Test("Version is correct")
    func versionIsCorrect() {
        #expect(ARCDevTools.version == "1.0.0")
    }

    // MARK: Bundle Tests

    @Test("Bundle exists")
    func bundleExists() {
        let bundle = ARCDevTools.bundle
        // Bundle is always non-nil, just verify it's accessible
        #expect(bundle.bundleIdentifier != nil || bundle.bundlePath.isEmpty == false)
    }

    // MARK: Config Resources Tests

    @Test("SwiftLint config exists")
    func swiftLintConfigExists() {
        let config = ARCDevTools.swiftlintConfig
        #expect(config != nil, "SwiftLint config should exist")

        if let url = config {
            #expect(FileManager.default.fileExists(atPath: url.path), "SwiftLint config file should exist at path")
        }
    }

    @Test("SwiftFormat config exists")
    func swiftFormatConfigExists() {
        let config = ARCDevTools.swiftformatConfig
        #expect(config != nil, "SwiftFormat config should exist")

        if let url = config {
            #expect(FileManager.default.fileExists(atPath: url.path), "SwiftFormat config file should exist at path")
        }
    }

    // MARK: Scripts Directory Tests

    @Test("Scripts directory exists")
    func scriptsDirectoryExists() {
        let scriptsDir = ARCDevTools.scriptsDirectory
        #expect(scriptsDir != nil, "Scripts directory should exist")

        if let url = scriptsDir {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            #expect(exists, "Scripts directory should exist at path")
            #expect(isDirectory.boolValue, "Scripts path should be a directory")
        }
    }

    // MARK: Templates Directory Tests

    @Test("Templates directory exists")
    func templatesDirectoryExists() {
        let templatesDir = ARCDevTools.templatesDirectory
        #expect(templatesDir != nil, "Templates directory should exist")

        if let url = templatesDir {
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            #expect(exists, "Templates directory should exist at path")
            #expect(isDirectory.boolValue, "Templates path should be a directory")
        }
    }

    // MARK: Utilities Tests

    @Test("Copy resource creates destination")
    func copyResourceCreatesDestination() throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.txt")
        let destination = tempDir.appendingPathComponent("copied.txt")

        // Create source file
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)

        // When
        try ARCDevTools.copyResource(from: testFile, to: destination)

        // Then
        #expect(FileManager.default.fileExists(atPath: destination.path))

        let content = try String(contentsOf: destination)
        #expect(content == "Test content")

        // Cleanup
        try? FileManager.default.removeItem(at: testFile)
        try? FileManager.default.removeItem(at: destination)
    }

    @Test("Make executable sets correct permissions")
    func makeExecutableSetsCorrectPermissions() throws {
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
        #expect(permissions != nil)
        #expect(permissions?.uint16Value == 0o755)

        // Cleanup
        try? FileManager.default.removeItem(at: scriptFile)
    }

    // MARK: Configuration Tests

    @Test("Default configuration has correct values")
    func defaultConfigurationHasCorrectValues() {
        let config = ARCConfiguration.default

        #expect(config.lintRules.warningThreshold == 10)
        #expect(config.lintRules.errorThreshold == 50)
        #expect(config.formatRules.indent == 4)
        #expect(config.formatRules.maxWidth == 120)
        #expect(config.enablePreCommitHooks == true)
        #expect(config.autoFormat == true)
    }

    @Test("Configuration persistence works correctly")
    func configurationPersistenceWorksCorrectly() throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let configFile = tempDir.appendingPathComponent("test-config.json")
        let config = ARCConfiguration.default

        // When
        try config.save(to: configFile)

        // Then
        #expect(FileManager.default.fileExists(atPath: configFile.path))

        let loadedConfig = ARCConfiguration.load(from: configFile)
        #expect(loadedConfig.lintRules.warningThreshold == config.lintRules.warningThreshold)
        #expect(loadedConfig.formatRules.indent == config.formatRules.indent)

        // Cleanup
        try? FileManager.default.removeItem(at: configFile)
    }
}
