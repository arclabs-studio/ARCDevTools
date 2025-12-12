# Integrating ARCDevTools in Your Code

Learn how to access and use ARCDevTools resources programmatically.

## Overview

While ARCDevTools is primarily used for its configuration files and setup scripts, it also provides a Swift API for accessing resources programmatically. This is useful when building tools or scripts that need to work with ARCDevTools configurations.

## Accessing Configuration Files

ARCDevTools provides URLs to its configuration files:

### SwiftLint Configuration

```swift
import ARCDevTools

if let swiftlintURL = ARCDevTools.swiftlintConfig {
    print("SwiftLint config: \(swiftlintURL.path)")

    // Read the configuration
    let contents = try String(contentsOf: swiftlintURL)

    // Use in your tooling
    // ...
}
```

### SwiftFormat Configuration

```swift
import ARCDevTools

if let swiftformatURL = ARCDevTools.swiftformatConfig {
    print("SwiftFormat config: \(swiftformatURL.path)")

    // Use the configuration
    // ...
}
```

## Accessing Resource Directories

### Scripts Directory

Access the scripts directory to get pre-commit hooks and other automation scripts:

```swift
import ARCDevTools

if let scriptsDir = ARCDevTools.scriptsDirectory {
    let preCommitHook = scriptsDir.appendingPathComponent("pre-commit")
    let prePushHook = scriptsDir.appendingPathComponent("pre-push")

    if FileManager.default.fileExists(atPath: preCommitHook.path) {
        print("Found pre-commit hook at: \(preCommitHook.path)")
    }

    if FileManager.default.fileExists(atPath: prePushHook.path) {
        print("Found pre-push hook at: \(prePushHook.path)")
    }
}
```

## Utility Functions

### Copying Resources

Use ``ARCDevTools/copyResource(from:to:)`` to copy files with automatic directory creation:

```swift
import ARCDevTools

let source = ARCDevTools.swiftlintConfig!
let destination = URL(fileURLWithPath: "/path/to/project/.swiftlint.yml")

do {
    try ARCDevTools.copyResource(from: source, to: destination)
    print("✓ SwiftLint configuration copied")
} catch {
    print("✗ Failed to copy: \(error)")
}
```

This function:
- Creates parent directories if needed
- Removes existing files at the destination
- Copies the file atomically

### Making Scripts Executable

Use ``ARCDevTools/makeExecutable(_:)`` to set executable permissions on shell scripts:

```swift
import ARCDevTools

let scriptURL = URL(fileURLWithPath: "/path/to/script.sh")

do {
    try ARCDevTools.makeExecutable(scriptURL)
    print("✓ Script is now executable")
} catch {
    print("✗ Failed to make executable: \(error)")
}
```

This sets permissions to `0o755` (rwxr-xr-x).

## Building Custom Setup Tools

You can build custom setup tools using ARCDevTools as a foundation:

```swift
import Foundation
import ARCDevTools

@main
struct MyCustomSetup {
    static func main() async throws {
        print("🔧 Custom Project Setup")

        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        // Copy SwiftLint configuration
        if let swiftlintConfig = ARCDevTools.swiftlintConfig {
            let destination = projectRoot.appendingPathComponent(".swiftlint.yml")
            try ARCDevTools.copyResource(from: swiftlintConfig, to: destination)
            print("✓ SwiftLint configured")
        }

        // Copy SwiftFormat configuration
        if let swiftformatConfig = ARCDevTools.swiftformatConfig {
            let destination = projectRoot.appendingPathComponent(".swiftformat")
            try ARCDevTools.copyResource(from: swiftformatConfig, to: destination)
            print("✓ SwiftFormat configured")
        }

        // Additional custom setup
        // ...

        print("✅ Setup complete!")
    }
}
```

## Configuration Model

ARCDevTools includes an ``ARCConfiguration`` model for managing configuration programmatically:

```swift
import ARCDevTools

// Load configuration
let config = ARCConfiguration.default

print("Warning threshold: \(config.lintRules.warningThreshold)")
print("Indent: \(config.formatRules.indent)")
print("Pre-commit hooks enabled: \(config.enablePreCommitHooks)")

// Save configuration
let customConfig = ARCConfiguration(
    lintRules: .default,
    formatRules: .default,
    enablePreCommitHooks: true,
    autoFormat: true
)

let configFile = URL(fileURLWithPath: "arc-config.json")
try customConfig.save(to: configFile)
```

## See Also

- ``ARCDevTools``
- ``ARCConfiguration``
- <doc:Configuration>
