# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- Claude Code skills support in ARCDevTools
- `arc-package-validator` skill: validates Swift Packages against ARCKnowledge standards
  - Structure validation (Package.swift, README, LICENSE, etc.)
  - Configuration validation (ARCDevTools integration, SwiftLint, SwiftFormat)
  - Documentation validation (badges, required sections)
  - Code quality validation (SwiftLint execution, SwiftFormat check, build)
  - Auto-fix mode with `--fix` flag
- `arcdevtools-setup` now installs Claude Code skills automatically

---

## [1.0.0] - 2025-12-17

### 🎉 Initial Release

ARCDevTools v1.0.0 is the first production-ready release, providing **centralized quality tooling and standards for ARC Labs Studio projects**.

ARCDevTools is a **configuration repository** integrated as a **Git submodule**, offering standardized SwiftLint and SwiftFormat configurations, git hooks, GitHub Actions workflow templates, and automation scripts.

### Features

#### Core Functionality

- ✅ **arcdevtools-setup Script** - Swift script (`#!/usr/bin/env swift`) for one-command project setup
  - Copies SwiftLint and SwiftFormat configurations
  - Installs git hooks (pre-commit, pre-push)
  - Generates Makefile with convenient commands
  - Optionally copies GitHub Actions workflow templates

#### Configuration Files

- ✅ **SwiftLint Configuration** (`configs/swiftlint.yml`)
  - 40+ linting rules aligned with ARCKnowledge standards
  - Custom rules for ARC Labs-specific patterns
  - Analyzer rules for unused imports and declarations

- ✅ **SwiftFormat Configuration** (`configs/swiftformat`)
  - 4-space indentation
  - 120-character line width
  - Omit `self` when not required
  - Consistent code formatting across all projects

#### Git Hooks

- ✅ **Pre-commit Hook** (`hooks/pre-commit`)
  - Automatically formats Swift files with SwiftFormat
  - Runs SwiftLint in strict mode
  - Blocks commit if linting fails

- ✅ **Pre-push Hook** (`hooks/pre-push`)
  - Runs all tests before pushing
  - Prevents broken code from reaching remote

- ✅ **Hook Installation Script** (`hooks/install-hooks.sh`)

#### GitHub Actions Workflows

- ✅ **quality.yml** - Code quality checks (SwiftLint, SwiftFormat, Markdown link validation)
- ✅ **tests.yml** - Automated testing on macOS and Linux
- ✅ **docs.yml** - Documentation generation and deployment
- ✅ **enforce-gitflow.yml** - Git Flow branch validation
- ✅ **sync-develop.yml** - Auto-sync main → develop
- ✅ **validate-release.yml** - Release validation and creation
- ✅ **release-drafter.yml** - Auto-draft release notes from PRs

#### Utility Scripts

- ✅ **lint.sh** - Run SwiftLint
- ✅ **format.sh** - Run SwiftFormat
- ✅ **setup-github-labels.sh** - Configure GitHub labels
- ✅ **setup-branch-protection.sh** - Configure branch protection rules

#### GitHub Templates

- ✅ **PULL_REQUEST_TEMPLATE.md** - PR template with comprehensive checklist
- ✅ **release-drafter.yml** - Release notes configuration
- ✅ **markdown-link-check-config.json** - Link validation settings

#### Documentation

- ✅ **Complete Markdown documentation** in `docs/` directory:
  - `getting-started.md` - Installation and setup walkthrough
  - `integration.md` - Detailed integration instructions
  - `configuration.md` - Customization options and best practices
  - `ci-cd.md` - GitHub Actions setup guide
  - `troubleshooting.md` - Common issues and solutions

- ✅ **README.md** - Comprehensive project overview and usage guide
- ✅ **CONTRIBUTING.md** - Contribution guidelines with Git Flow workflow
- ✅ **CHANGELOG.md** - This file

#### Standards Compliance

- ✅ **ARCKnowledge Integration** - Development standards included as submodule
- ✅ **All code and documentation in English**
- ✅ **File headers on all source files**
- ✅ **100% aligned with ARCKnowledge standards**

### Architecture

ARCDevTools follows a **clean directory structure**:

```
ARCDevTools/
├── arcdevtools-setup                       # Swift setup script
├── configs/                        # SwiftLint and SwiftFormat configs
├── hooks/                          # Git hooks
├── scripts/                        # Utility scripts
├── workflows/                      # GitHub Actions templates
├── templates/                      # GitHub templates
├── docs/                           # Markdown documentation
├── ARCKnowledge/                   # Development standards (submodule)
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

### Installation

Projects integrate ARCDevTools as a **Git submodule**:

```bash
# Add submodule
git submodule add https://github.com/arclabs-studio/ARCDevTools
git submodule update --init --recursive

# Run setup
./ARCDevTools/arcdevtools-setup

# Commit integration
git add .gitmodules ARCDevTools/ .swiftlint.yml .swiftformat Makefile
git commit -m "chore: integrate ARCDevTools v1.0"
```

### Benefits

- ⚡️ **Fast setup** - No compilation required, pure configuration
- 📁 **Direct access** - All resources visible in filesystem
- 🎨 **Easy customization** - Fork and modify without package complexity
- 🔧 **Universal compatibility** - Works with Swift packages and Xcode projects
- 🚀 **Simple CI/CD** - Just `git submodule update --init --recursive`
- 📖 **Clear documentation** - Standard Markdown format
- 🔍 **Transparent** - All configs and scripts directly visible

---

## Links

- **Repository**: https://github.com/arclabs-studio/ARCDevTools
- **ARCKnowledge**: https://github.com/arclabs-studio/ARCKnowledge
- **Issues**: https://github.com/arclabs-studio/ARCDevTools/issues

---

[Unreleased]: https://github.com/arclabs-studio/ARCDevTools/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v1.0.0
