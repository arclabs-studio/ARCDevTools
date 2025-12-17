# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [2.0.0] - 2025-12-17

### 🚀 BREAKING CHANGES

**Major Architecture Change:** ARCDevTools is now a pure configuration repository integrated as a Git submodule instead of a Swift Package Manager dependency.

#### What Changed

1. **Installation Method**: Git submodule instead of SPM package
2. **Setup Command**: `./ARCDevTools/arc-setup` instead of `swift run arc-setup`
3. **No Swift API**: Removed `import ARCDevTools` support - pure configuration repository
4. **Resource Paths**: Direct filesystem access (`ARCDevTools/configs/`) instead of Bundle.module
5. **No Compilation**: Swift script instead of compiled executable

#### Migration Required

See [docs/MIGRATION_V1_TO_V2.md](docs/MIGRATION_V1_TO_V2.md) for complete upgrade instructions from v1.x.

### Changed

#### Architecture Transformation

- ✅ **Converted from SPM package to configuration repository** - No longer requires Swift Package Manager
- ✅ **New directory structure** - Clean organization: `configs/`, `hooks/`, `scripts/`, `workflows/`, `templates/`, `docs/`
- ✅ **Swift script instead of compiled executable** - `arc-setup` is now a Swift script with shebang (`#!/usr/bin/env swift`)
  - Faster to distribute (no compilation)
  - Easy to read and modify
  - Maintains Swift code clarity
- ✅ **Removed ARCAgentsDocs SPM dependency** - ARCKnowledge now added as git submodule
- ✅ **Updated all references** - All documentation and configurations now reference ARCKnowledge
  - Updated README.md, CONTRIBUTING.md, CHANGELOG.md
  - Updated SwiftLint configuration comments

#### Documentation

- ✅ **Converted DocC to Markdown** - All documentation now in standard Markdown format
- ✅ **New docs structure** - Comprehensive guides in `docs/`:
  - `getting-started.md` - Installation with submodule
  - `integration.md` - Detailed integration guide
  - `configuration.md` - Customization options
  - `ci-cd.md` - GitHub Actions setup
  - `troubleshooting.md` - Common issues
  - `MIGRATION_V1_TO_V2.md` - Upgrade guide from v1.x
- ✅ **Completely rewritten README.md** - Reflects new submodule-based installation

### Added

#### New Features

- ✅ **Git submodule integration** - Projects add ARCDevTools as `git submodule add https://github.com/arclabs-studio/ARCDevTools`
- ✅ **ARCKnowledge submodule** - Development standards included at `ARCKnowledge/` directory
- ✅ **GitHub Actions workflow templates** - All 7 workflows available in `workflows/`:
  - `quality.yml` - Code quality checks
  - `tests.yml` - Testing on macOS and Linux
  - `docs.yml` - Documentation generation
  - `enforce-gitflow.yml` - Git Flow validation
  - `sync-develop.yml` - Auto-sync main → develop
  - `validate-release.yml` - Release validation
  - `release-drafter.yml` - Auto-draft release notes
- ✅ **Template header in workflows** - Copied workflows include source attribution
- ✅ **Migration guide** - Complete v1.x to v2.x upgrade documentation

### Removed

- ❌ **Package.swift** - No longer a Swift package
- ❌ **Swift Package structure** - Removed `Sources/`, `Tests/`, `.swiftpm/`, `.build/`
- ❌ **SPM executable** - Removed compiled `arc-setup` executable
- ❌ **ARCDevTools Swift library** - Removed `ARCDevToolsCore.swift`, `ARCConfiguration.swift`
- ❌ **Swift API** - `import ARCDevTools` no longer works
- ❌ **Bundle.module resources** - Direct filesystem access instead
- ❌ **DocC documentation** - Converted to standard Markdown
- ❌ **Test suite** - Removed Tests/ (tested manually via arc-setup execution)

### Benefits of v2.0.0

- ⚡️ **Faster setup** - No Swift compilation required
- 📁 **Direct access** - All resources visible in filesystem
- 🎨 **Easier to customize** - Fork and modify without SPM complexity
- 🔧 **Universal compatibility** - Works with any project type (not just Swift packages)
- 🚀 **Simpler CI/CD** - Just `git submodule update --init --recursive`
- 📖 **Better documentation** - Standard Markdown instead of DocC
- 🔍 **Transparent** - All configs and scripts directly visible

### File Organization

```
ARCDevTools/
├── arc-setup                       # Swift script (replaces compiled executable)
├── configs/                        # Configuration files
│   ├── swiftlint.yml              # (moved from Sources/.../Configs/)
│   └── swiftformat                # (moved from Sources/.../Configs/)
├── hooks/                          # Git hooks
│   ├── pre-commit                 # (moved from Sources/.../Scripts/)
│   ├── pre-push                   # (moved from Sources/.../Scripts/)
│   └── install-hooks.sh           # (moved from Sources/.../Scripts/)
├── scripts/                        # Utility scripts
│   ├── lint.sh                    # (moved from Sources/.../Scripts/)
│   ├── format.sh                  # (moved from Sources/.../Scripts/)
│   ├── setup-github-labels.sh     # (preserved from scripts/)
│   └── setup-branch-protection.sh # (preserved from scripts/)
├── workflows/                      # GitHub Actions templates
│   └── *.yml                      # (moved from .github/workflows/)
├── templates/                      # GitHub templates
│   ├── PULL_REQUEST_TEMPLATE.md   # (moved from .github/)
│   ├── release-drafter.yml        # (moved from .github/)
│   └── markdown-link-check-config.json
├── docs/                           # Documentation
│   └── *.md                       # (converted from Documentation.docc/)
├── ARCKnowledge/                   # Submodule (preserved)
├── README.md                       # (completely rewritten)
├── CHANGELOG.md                    # (this file)
├── CONTRIBUTING.md                 # (updated for submodule workflow)
└── LICENSE                         # (preserved)
```

---

## [1.1.3] - 2024-12-16

### Added

#### Complete CI/CD Automation
- ✅ **New GitHub Actions Workflows:**
  - `sync-develop.yml` - Automatically syncs `main` → `develop` after merges
    - Creates issue if conflicts occur
    - Prevents branch divergence
  - `validate-release.yml` - Validates tags and creates GitHub Releases
    - Validates semver format (vX.Y.Z)
    - Checks CHANGELOG.md entries
    - Builds and tests release configuration
  - `release-drafter.yml` - Auto-generates release notes from PRs
    - Categorizes by labels (features, bugs, docs, etc.)
    - Suggests next version number
  - `enforce-gitflow.yml` - Validates Git Flow rules
    - Ensures `feature/*` → `develop` only
    - Ensures `hotfix/*` → `main` only
    - Validates branch naming conventions
    - Warns on non-conventional commits

- ✅ **Enhanced Existing Workflows:**
  - `quality.yml` - Added markdown link validation job
  - `docs.yml` - Enabled GitHub Pages deployment for DocC

- ✅ **Configuration Files:**
  - `.github/PULL_REQUEST_TEMPLATE.md` - PR template with comprehensive checklist
  - `.github/release-drafter.yml` - Release notes configuration with categorization
  - `.github/markdown-link-check-config.json` - Link validation settings
  - `CONTRIBUTING.md` - Complete contribution guide with:
    - Git Flow workflow (feature → develop → main)
    - Conventional Commits specification
    - Pull request process
    - CI/CD workflows explanation
    - Troubleshooting guide

- ✅ **Automation Scripts:**
  - `scripts/setup-branch-protection.sh` - Configure branch protection rules via GitHub CLI
  - `scripts/setup-github-labels.sh` - Create labels for Release Drafter categorization

- ✅ **Documentation:**
  - README.md updated with workflow status badges
  - README.md added comprehensive CI/CD automation section
  - Complete workflow documentation for all 7 automation workflows

### Removed
- **Templates system** - Removed all code generation templates and related functionality
  - Deleted `Sources/ARCDevTools/Resources/Templates/` directory
  - Removed `templatesDirectory` property from public API
  - Removed `setupTemplates` function from arc-setup
  - Removed templates-related tests
  - Updated all documentation to remove template references
  - **Reason:** Templates didn't match desired format; users can implement their own scaffolding

### Fixed
- **SwiftLint configuration** - Removed overly aggressive custom rules
  - Disabled `sorted_imports` rule to allow `@testable import` at the end
  - Removed custom `force_unwrap_production` rule (was detecting `!` in logical negations and comparisons)
  - Removed custom `print_statement` rule (legitimate for CLI tools like arc-setup)
  - Keep using built-in `force_unwrapping` rule which is more intelligent

### Planned
- Custom `.arcconfig.json` configuration support
- Swift Macros for reducing boilerplate

---

## [1.0.0] - 2025-12-12

### 🎉 Production Release

ARCDevTools v1.0.0 marks the **production-ready** release with 100% alignment to ARCKnowledge standards. This release includes comprehensive quality improvements, modern testing, complete documentation, and automated CI/CD.

### Added

#### Testing Framework
- ✅ Migrated from XCTest to **Swift Testing framework**
- ✅ All tests use `@Test` attributes and `#expect` assertions
- ✅ Test suites organized with `@Suite` for better structure
- ✅ Descriptive test names following ARCKnowledge conventions
- ✅ 100% test coverage maintained with modern syntax

#### Code Quality & Linting
- ✅ **Expanded SwiftLint rules**: 9 → 36 opt-in rules
- ✅ Added 3 new custom rules:
  - `no_empty_line_after_guard` - Enforce clean guard formatting
  - `no_force_cast` - Require safe casting with `as?`
  - `no_force_try` - Require proper error handling
- ✅ Analyzer rules: `unused_import`, `unused_declaration`
- ✅ All rules aligned with ARCKnowledge code-style.md standards

#### Code Formatting
- ✅ SwiftFormat: Changed `--self insert` → `--self remove` (ARCKnowledge standard)
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
- ✅ **100% aligned with ARCKnowledge**

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

⚠️ **Breaking changes in v1.0.0:**

1. **Testing Framework Change**
   - Tests now use Swift Testing instead of XCTest
   - Test syntax changed: `@Test` attributes, `#expect` assertions
   - **Action**: Update test imports and assertions if referencing

2. **SwiftFormat Behavior**
   - `--self remove` replaces `--self insert`
   - Explicit `self` will be removed by formatter
   - **Action**: Run `make fix` to apply changes

### Migration Guide

If upgrading to v1.0.0:

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

## Links

- **Repository**: https://github.com/arclabs-studio/ARCDevTools
- **ARCKnowledge**: https://github.com/arclabs-studio/ARCKnowledge
- **Issues**: https://github.com/arclabs-studio/ARCDevTools/issues

---

[Unreleased]: https://github.com/arclabs-studio/ARCDevTools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v1.0.0
