# 🛠️ ARCDevTools

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)

[![Tests](https://github.com/arclabs-studio/ARCDevTools/workflows/Tests/badge.svg)](https://github.com/arclabs-studio/ARCDevTools/actions/workflows/tests.yml)
[![Code Quality](https://github.com/arclabs-studio/ARCDevTools/workflows/Code%20Quality/badge.svg)](https://github.com/arclabs-studio/ARCDevTools/actions/workflows/quality.yml)
[![Documentation](https://github.com/arclabs-studio/ARCDevTools/workflows/Documentation/badge.svg)](https://github.com/arclabs-studio/ARCDevTools/actions/workflows/docs.yml)

**Centralized quality tooling and standards for ARC Labs Studio**

Quality automation • Code formatting • Linting • Git hooks • CI/CD


---

## 🎯 Overview

ARCDevTools is a Swift package that provides standardized development tooling for all ARC Labs projects. It bundles SwiftLint and SwiftFormat configurations, pre-commit and pre-push hooks, and automation scripts to ensure consistency and reduce configuration drift across the ecosystem.

### Key Features

- ✅ **Pre-configured SwiftLint** - Comprehensive linting rules aligned with ARC Labs standards
- ✅ **Pre-configured SwiftFormat** - Automatic code formatting with consistent style
- ✅ **Git Hooks** - Automated quality checks on commit and push
- ✅ **Project Setup** - One-command setup for new and existing projects
- ✅ **Makefile Generation** - Convenient commands for common tasks

---

## 📋 Requirements

- **Swift:** 6.0+
- **Platforms:** macOS 13.0+ / iOS 17.0+
- **Xcode:** 16.0+
- **Tools:** SwiftLint, SwiftFormat (installed via Homebrew)

---

## 🚀 Installation

### 1. Clone with Submodules

ARCDevTools includes ARCKnowledge as a git submodule for development standards documentation.

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/arclabs-studio/ARCDevTools

# Or if already cloned, initialize submodules
git submodule update --init --recursive
```

### 2. Add Package Dependency

#### For Swift Packages

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/arclabs-studio/ARCDevTools", from: "1.0.0")
]
```

#### For Xcode Projects

1. **File → Add Package Dependencies**
2. Enter: `https://github.com/arclabs-studio/ARCDevTools`
3. Select version: `1.0.0` or later
4. **Important:** Do not add to any target (development tools only)

### 3. Install Required Tools

```bash
brew install swiftlint swiftformat
```

### 4. Run Setup

```bash
# From your project root
swift run arc-setup
```

This will install:
- `.swiftlint.yml` configuration
- `.swiftformat` configuration
- Pre-commit and pre-push git hooks
- `Makefile` with useful commands

---

## 📖 Usage

### Available Commands

After running `arc-setup`, you'll have access to these make commands:

```bash
make help          # Show all available commands
make lint          # Run SwiftLint
make format        # Preview formatting changes (dry-run)
make fix           # Apply SwiftFormat automatically
make setup         # Re-run ARCDevTools setup
make clean         # Remove build artifacts
```

### Manual Configuration Access

```swift
import ARCDevTools

// Access configuration files
let swiftlintConfig = ARCDevTools.swiftlintConfig
let swiftformatConfig = ARCDevTools.swiftformatConfig

// Access resource directories
let scripts = ARCDevTools.scriptsDirectory

// Copy resources
try ARCDevTools.copyResource(from: source, to: destination)

// Make scripts executable
try ARCDevTools.makeExecutable(scriptURL)
```

---

## 📐 Code Style Standards

ARCDevTools enforces the following standards (aligned with [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)):

### SwiftFormat Configuration

- **Indentation:** 4 spaces
- **Line width:** 120 characters
- **Self keyword:** Omit when not required (`--self remove`)
- **Imports:** Grouped and sorted, testable imports at bottom
- **Braces:** Same-line (`--allman false`)

### SwiftLint Rules

- **~40 opt-in rules** for comprehensive quality checks
- **Custom rules** for ARC Labs-specific patterns:
  - `observable_viewmodel` - ViewModels must use `@Observable`
  - `no_force_cast` - Avoid `as!`, use `as?`
  - `no_force_try` - Avoid `try!`, use proper error handling
  - `no_empty_line_after_guard` - Clean guard statement formatting
  - `print_statement` - Replace `print()` with structured logging

### Architecture Standards

- **Pattern:** MVVM + Clean Architecture
- **ViewModels:** Use `@Observable` (Swift 6)
- **Dependencies:** Protocol-based with dependency injection
- **Testing:** Swift Testing framework

For complete standards, see [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge).

---

## 🛠️ Customization

### Overriding SwiftLint Rules

Create a `.swiftlint.yml` in your project:

```yaml
# Inherit from ARCDevTools
parent_config: .swiftlint.yml

# Add project-specific rules
disabled_rules:
  - line_length  # Example: disable if needed

custom_rules:
  my_custom_rule:
    name: "My Custom Rule"
    regex: "..."
    message: "Custom message"
    severity: warning
```

### Disabling Pre-commit Hooks

Temporarily bypass hooks when needed:

```bash
git commit --no-verify -m "commit message"
```

---

## 🏗️ Project Structure

```
ARCDevTools/
├── Sources/
│   ├── ARCDevTools/
│   │   ├── ARCDevToolsCore.swift      # Public API
│   │   ├── Models/
│   │   │   └── ARCConfiguration.swift # Configuration model
│   │   └── Resources/
│   │       ├── Configs/               # SwiftLint & SwiftFormat
│   │       └── Scripts/               # Git hooks & automation
│   └── arc-setup/
│       └── main.swift                 # Setup executable
└── Tests/
    └── ARCDevToolsTests/
        └── ARCDevToolsTests.swift     # Swift Testing tests
```

---

## 🧪 Testing

ARCDevTools uses the Swift Testing framework:

```bash
swift test
```

All tests follow ARCKnowledge standards:
- Descriptive test names with `@Test` attributes
- `#expect` assertions instead of `XCTAssert*`
- Suite organization with `@Suite` attributes

---

## 🤝 Contributing

ARCDevTools is an internal package for ARC Labs Studio. Contributions from team members are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines on:
- Git Flow workflow (feature → develop → main)
- Conventional Commits format
- Pull request process
- Code quality standards
- CI/CD automation

**Quick start:**
1. Create a feature branch: `feature/your-improvement`
2. Follow the standards defined in [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)
3. Ensure all tests pass: `swift test --parallel`
4. Run quality checks: `make lint && make format`
5. Create a pull request to `develop`

---

## 🤖 CI/CD Automation

ARCDevTools uses comprehensive GitHub Actions automation to ensure quality and streamline development:

### Workflows

#### Tests (`tests.yml`)
- **Triggers:** Push to main/develop/feature/*, PR to main/develop
- **Platforms:** macOS (Xcode 16) + Linux (Swift 6.0)
- **Actions:** Build package, run all tests in parallel
- **Purpose:** Ensure code compiles and tests pass on all platforms

#### Code Quality (`quality.yml`)
- **Triggers:** Push to main/develop/feature/*, PR to main/develop
- **Checks:**
  - SwiftLint (strict mode with 40+ rules)
  - SwiftFormat (lint mode)
  - Markdown link validation
- **Purpose:** Enforce code style and documentation quality

#### Documentation (`docs.yml`)
- **Triggers:** Push to main, manual
- **Actions:**
  - Generate DocC documentation
  - Deploy to GitHub Pages
  - Upload artifacts (30-day retention)
- **Purpose:** Keep documentation up-to-date and accessible

#### Git Flow Enforcement (`enforce-gitflow.yml`)
- **Triggers:** PR to main/develop
- **Validates:**
  - `feature/*` → `develop` only
  - `hotfix/*` → `main` only
  - `develop` or `hotfix/*` → `main` only
  - Conventional commit format (warnings)
- **Purpose:** Maintain clean branching strategy

#### Sync Develop (`sync-develop.yml`)
- **Triggers:** Push to main
- **Actions:** Automatically merge main → develop
- **Conflict Handling:** Creates issue if manual resolution needed
- **Purpose:** Keep develop in sync with main

#### Release Validation (`validate-release.yml`)
- **Triggers:** Tag push (v*.*.*)
- **Validates:**
  - Semver tag format
  - CHANGELOG.md entry
  - Tag on main branch
- **Actions:** Build release, run tests, create GitHub Release
- **Purpose:** Ensure releases are properly formatted and tested

#### Release Drafter (`release-drafter.yml`)
- **Triggers:** Push to main, PR events
- **Actions:** Auto-generate release notes from PRs
- **Categorizes:** Features, bug fixes, docs, architecture, etc.
- **Purpose:** Automated release note generation

### Branch Protection

Both `main` and `develop` branches are protected:

**main:**
- Requires 1 approval
- All status checks must pass
- Linear history required
- No force pushes or deletions

**develop:**
- Status checks must pass
- No force pushes or deletions

### Setup Scripts

After cloning, you can configure GitHub settings:

```bash
# Configure branch protection rules
./scripts/setup-branch-protection.sh

# Create labels for Release Drafter
./scripts/setup-github-labels.sh
```

**Note:** Requires GitHub CLI (`gh`) with admin permissions.

---

## 📄 License

Proprietary © 2025 ARC Labs Studio

---

## 🔗 Related Resources

- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** - Complete development standards and guidelines
- **[SwiftLint](https://github.com/realm/SwiftLint)** - A tool to enforce Swift style and conventions
- **[SwiftFormat](https://github.com/nicklockwood/SwiftFormat)** - Code formatting for Swift

---

<div align="center">

Made with 💛 by ARC Labs Studio

</div>
