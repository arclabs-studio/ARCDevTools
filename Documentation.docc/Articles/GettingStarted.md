# Getting Started with ARCDevTools

Set up quality automation for your ARC Labs project in minutes.

## Overview

ARCDevTools provides a streamlined setup process that configures SwiftLint, SwiftFormat, git hooks, and automation scripts for your project. This guide walks you through the initial setup and basic usage.

## Requirements

Before you begin, ensure you have:

- **Swift 6.0** or later
- **macOS 13.0** or **iOS 17.0** or later
- **Xcode 16.0** or later
- **Homebrew** installed on your system

## Installation Steps

### Step 1: Install Required Tools

First, install SwiftLint and SwiftFormat using Homebrew:

```bash
brew install swiftlint swiftformat
```

These tools are required for ARCDevTools to function properly.

### Step 2: Add ARCDevTools as a Dependency

#### For Swift Packages

Add ARCDevTools to your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourPackage",
    dependencies: [
        .package(url: "https://github.com/arclabs-studio/ARCDevTools", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourTarget",
            dependencies: []
        )
    ]
)
```

**Note:** ARCDevTools should NOT be added to target dependencies—it's a development tool only.

#### For Xcode Projects

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter the repository URL: `https://github.com/arclabs-studio/ARCDevTools`
4. Select version `1.0.0` or later
5. **Important:** Do not add ARCDevTools to any target

### Step 3: Run Setup

Navigate to your project root directory and run the setup command:

```bash
cd /path/to/your/project
swift run arc-setup
```

The setup tool will:

1. ✅ Copy `.swiftlint.yml` configuration to your project
2. ✅ Copy `.swiftformat` configuration to your project
3. ✅ Install pre-commit and pre-push git hooks (if `.git/` exists)
4. ✅ Generate a `Makefile` with useful commands

## Verify Installation

After setup completes, verify everything is working:

### Test SwiftLint

```bash
make lint
```

This should run SwiftLint on your codebase and report any style violations.

### Test SwiftFormat

```bash
make format
```

This runs SwiftFormat in lint mode (dry-run) to show what would change.

### Apply Formatting

```bash
make fix
```

This applies SwiftFormat changes to your code.

## Next Steps

Now that ARCDevTools is installed, you can:

- Read <doc:Integration> to learn how to use ARCDevTools in your code
- Check <doc:Configuration> to customize rules for your project
- See <doc:Troubleshooting> if you encounter any issues

## See Also

- <doc:Integration>
- <doc:Configuration>
- <doc:Troubleshooting>
