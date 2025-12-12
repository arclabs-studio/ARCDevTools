# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- `arc-generate` command for feature scaffolding from CLI
- Custom `.arcconfig.json` configuration support
- Swift Macros for reducing boilerplate

---

## [1.0.0] - 2025-12-12

### 🎉 Production Release

ARCDevTools v1.0.0 marks the **production-ready** release with 100% alignment to ARCAgentsDocs standards. This release includes comprehensive quality improvements, modern testing, complete documentation, and automated CI/CD.

### Added

#### Testing Framework
- ✅ Migrated from XCTest to **Swift Testing framework**
- ✅ All tests use `@Test` attributes and `#expect` assertions
- ✅ Test suites organized with `@Suite` for better structure
- ✅ Descriptive test names following ARCAgentsDocs conventions
- ✅ 100% test coverage maintained with modern syntax

#### Code Quality & Linting
- ✅ **Expanded SwiftLint rules**: 9 → 36 opt-in rules
- ✅ Added 3 new custom rules:
  - `no_empty_line_after_guard` - Enforce clean guard formatting
  - `no_force_cast` - Require safe casting with `as?`
  - `no_force_try` - Require proper error handling
- ✅ Analyzer rules: `unused_import`, `unused_declaration`
- ✅ All rules aligned with ARCAgentsDocs code-style.md standards

#### Code Formatting
- ✅ SwiftFormat: Changed `--self insert` → `--self remove` (ARCAgentsDocs standard)
- ✅ Fixed configuration typo: `--classtreshold` → `--class-threshold`
- ✅ All code formatted with updated rules
- ✅ Consistent 4-space indentation, 120-char line width

#### Documentation
- ✅ **Complete DocC documentation catalog**
- ✅ **Five comprehensive guides:**
  - **Getting Started** - Installation and setup walkthrough
  - **Integration** - Programmatic API usage with examples
  - **Configuration** - Customization and best practices
  - **CI/CD Guide** - Complete GitHub Actions tutorial for beginners
  - **Troubleshooting** - Common issues and solutions
- ✅ Enhanced API documentation with code examples
- ✅ Topics organization for easy navigation
- ✅ All documentation in English

#### CI/CD Automation
- ✅ **GitHub Actions workflows:**
  - `quality.yml` - SwiftLint and SwiftFormat checks
  - `tests.yml` - Automated testing (macOS + Linux)
  - `docs.yml` - DocC documentation generation
- ✅ Cross-platform testing support
- ✅ Strict mode for pull requests
- ✅ Parallel test execution
- ✅ Artifact retention for documentation

#### Git Hooks
- ✅ **Pre-push hook** - Run tests before pushing
- ✅ Pre-commit hook - Run linting before committing
- ✅ Updated `arc-setup` to install both hooks
- ✅ Better error messages and user guidance

#### Standards Compliance
- ✅ File headers added to all Swift files
- ✅ All code translated to English
- ✅ All documentation translated to English
- ✅ README completely rewritten
- ✅ **100% aligned with ARCAgentsDocs**

### Changed

- **SwiftFormat**: `--self insert` → `--self remove`
- **SwiftLint**: Moved analyzer rules to dedicated section
- **SwiftLint**: Removed deprecated threshold config
- **README**: Completely rewritten in English
- **arc-setup**: Messages translated to English
- **Comments**: All Spanish comments → English

### Fixed

- ✅ Compilation errors in `arc-setup/main.swift`
- ✅ Bundle.module access issues
- ✅ SwiftFormat compatibility with latest version
- ✅ Test warnings (Bundle nil comparison)
- ✅ Import order in test files

### Breaking Changes

⚠️ **From 0.1.0:**

1. **Testing Framework Change**
   - Tests now use Swift Testing instead of XCTest
   - Test syntax changed: `@Test` attributes, `#expect` assertions
   - **Action**: Update test imports and assertions if referencing

2. **SwiftFormat Behavior**
   - `--self remove` replaces `--self insert`
   - Explicit `self` will be removed by formatter
   - **Action**: Run `make fix` to apply changes

### Migration Guide

If upgrading from 0.1.0:

```bash
# 1. Update configurations
swift run arc-setup

# 2. Apply new formatting
make fix

# 3. Check for violations
make lint

# 4. Run tests
swift test
```

---

## [0.1.0] - 2025-11-14

### Added

- 🎉 Initial ARCDevTools release
- ✅ SwiftLint and SwiftFormat configurations
- ✅ Shell scripts for lint, format, and git hooks
- ✅ Stencil templates for Features (View, ViewModel, Service)
- ✅ Unit test templates
- ✅ `arc-setup` executable for automatic configuration
- ✅ Automatic Makefile generation
- ✅ Pre-commit hooks for code validation
- ✅ Swift 6.0 support
- ✅ Basic documentation

### Features

- Public API via `ARCDevTools` enum
- Resource access via `Bundle.module`
- Configuration copy utilities
- Extensible configuration with `ARCConfiguration`

### Standards

- MVVM + Clean Architecture
- Swift 6 strict concurrency
- `@Observable` for ViewModels
- Protocol-oriented design

---

## Links

- **Repository**: https://github.com/arclabs-studio/ARCDevTools
- **ARCAgentsDocs**: https://github.com/arclabs-studio/ARCAgentsDocs
- **Issues**: https://github.com/arclabs-studio/ARCDevTools/issues

---

[Unreleased]: https://github.com/arclabs-studio/ARCDevTools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v1.0.0
[0.1.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v0.1.0
