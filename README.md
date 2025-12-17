# 🛠️ ARCDevTools

![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS-blue.svg)

**Centralized quality tooling and standards for ARC Labs Studio**

Quality automation • Code formatting • Linting • Git hooks • CI/CD

---

## 🎯 Overview

ARCDevTools is a configuration repository that provides standardized development tooling for all ARC Labs projects. It includes SwiftLint and SwiftFormat configurations, git hooks, GitHub Actions workflow templates, and automation scripts to ensure consistency across the ecosystem.

### Key Features

- ✅ **Pre-configured SwiftLint** - 40+ linting rules aligned with ARCKnowledge standards
- ✅ **Pre-configured SwiftFormat** - Consistent code formatting across all projects
- ✅ **Git Hooks** - Pre-commit and pre-push hooks for automated quality checks
- ✅ **GitHub Actions Workflows** - CI/CD templates for quality, testing, and releases
- ✅ **Project Setup Script** - One-command installation (`arc-setup`)
- ✅ **Makefile Generation** - Convenient commands for common tasks
- ✅ **ARCKnowledge Submodule** - Development standards documentation included

---

## 📋 Requirements

- **Swift:** 6.0+ (for Swift projects)
- **Platforms:** macOS 13.0+ / iOS 17.0+
- **Xcode:** 16.0+ (for Xcode projects)
- **Git:** 2.30+ (for submodule support)
- **Tools:** SwiftLint, SwiftFormat (installed via Homebrew)

---

## 🚀 Installation

### 1. Install Required Tools

```bash
brew install swiftlint swiftformat
```

### 2. Add ARCDevTools as Submodule

Navigate to your project root and add ARCDevTools:

```bash
cd /path/to/your/project
git submodule add https://github.com/arclabs-studio/ARCDevTools
git submodule update --init --recursive
```

This creates an `ARCDevTools/` directory in your project with all configuration files and scripts.

### 3. Run Setup Script

```bash
./ARCDevTools/arc-setup
```

The setup script will:
- ✅ Copy `.swiftlint.yml` to your project
- ✅ Copy `.swiftformat` to your project
- ✅ Install git hooks (pre-commit, pre-push)
- ✅ Generate `Makefile` with useful commands
- ✅ Optionally copy GitHub Actions workflows

### 4. Commit the Integration

```bash
git add .gitmodules ARCDevTools/ .swiftlint.yml .swiftformat Makefile
git commit -m "chore: integrate ARCDevTools v1.0 for quality automation"
git push
```

---

## 📖 Usage

### Available Commands

After setup, use the generated Makefile:

```bash
make help      # Show all available commands
make lint      # Run SwiftLint
make format    # Check formatting (dry-run)
make fix       # Apply SwiftFormat
make setup     # Re-run ARCDevTools setup
make hooks     # Re-install git hooks only
make clean     # Clean build artifacts
```

### Git Hooks

ARCDevTools installs automatic quality checks:

**Pre-commit hook:**
- Runs SwiftFormat on staged Swift files (auto-fixes)
- Runs SwiftLint in strict mode (must pass to commit)

**Pre-push hook:**
- Runs all tests before pushing (prevents broken code from reaching remote)

### Manual Configuration Access

All resources are directly accessible in the `ARCDevTools/` directory:

```bash
# Configuration files
ARCDevTools/configs/swiftlint.yml
ARCDevTools/configs/swiftformat

# Git hooks
ARCDevTools/hooks/pre-commit
ARCDevTools/hooks/pre-push
ARCDevTools/hooks/install-hooks.sh

# Utility scripts
ARCDevTools/scripts/lint.sh
ARCDevTools/scripts/format.sh
ARCDevTools/scripts/setup-github-labels.sh
ARCDevTools/scripts/setup-branch-protection.sh

# GitHub Actions workflow templates
ARCDevTools/workflows/quality.yml
ARCDevTools/workflows/tests.yml
ARCDevTools/workflows/docs.yml
ARCDevTools/workflows/enforce-gitflow.yml
ARCDevTools/workflows/sync-develop.yml
ARCDevTools/workflows/validate-release.yml
ARCDevTools/workflows/release-drafter.yml
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

- **40+ opt-in rules** for comprehensive quality checks
- **Custom rules** for ARC Labs-specific patterns:
  - `observable_viewmodel` - ViewModels must use `@Observable`
  - `no_force_cast` - Avoid `as!`, use `as?`
  - `no_force_try` - Avoid `try!`, use proper error handling
  - `no_empty_line_after_guard` - Clean guard statement formatting

### Architecture Standards

- **Pattern:** MVVM + Clean Architecture
- **ViewModels:** Use `@Observable` (Swift 6)
- **Dependencies:** Protocol-based with dependency injection
- **Testing:** Swift Testing framework

For complete standards, see [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge).

---

## 🛠️ Customization

### Override Default Configs

After running `arc-setup`, you can customize the copied configs:

```yaml
# .swiftlint.yml - Add project-specific rules
parent_config: .swiftlint.yml

disabled_rules:
  - line_length  # Example: disable if needed

custom_rules:
  my_custom_rule:
    name: "My Custom Rule"
    regex: "..."
    message: "Custom message"
    severity: warning
```

**Note:** Your customizations are preserved when updating ARCDevTools.

### GitHub Actions Workflows

Workflows are templates in `ARCDevTools/workflows/`. To use them:

1. Run `./ARCDevTools/arc-setup` and choose "Yes" when asked about workflows
2. Workflows are copied to `.github/workflows/`
3. Customize as needed for your project
4. Commit to your repository

Available workflows:
- `quality.yml` - SwiftLint, SwiftFormat, Markdown link checking
- `tests.yml` - Run tests on macOS and Linux
- `docs.yml` - Generate and publish DocC documentation
- `enforce-gitflow.yml` - Enforce Git Flow branch rules
- `sync-develop.yml` - Auto-sync main → develop
- `validate-release.yml` - Validate and create releases
- `release-drafter.yml` - Auto-draft release notes from PRs

---

## 🔄 Updating ARCDevTools

To get the latest configurations and scripts:

```bash
cd ARCDevTools
git pull origin main
cd ..
./ARCDevTools/arc-setup  # Re-run setup to update configs
git add ARCDevTools
git commit -m "chore: update ARCDevTools to latest version"
```

---

## 🏗️ Project Structure

```
ARCDevTools/
├── arc-setup                       # Installation script (bash)
├── configs/                        # Configuration files
│   ├── swiftlint.yml
│   └── swiftformat
├── hooks/                          # Git hooks
│   ├── pre-commit
│   ├── pre-push
│   └── install-hooks.sh
├── scripts/                        # Utility scripts
│   ├── lint.sh
│   ├── format.sh
│   ├── setup-github-labels.sh
│   └── setup-branch-protection.sh
├── workflows/                      # GitHub Actions templates
├── templates/                      # GitHub templates
├── docs/                           # Documentation
│   ├── README.md
│   ├── getting-started.md
│   ├── integration.md
│   ├── configuration.md
│   ├── ci-cd.md
│   ├── troubleshooting.md
│   └── MIGRATION_V1_TO_V2.md
├── ARCKnowledge/                   # Development standards (submodule)
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## 🧪 Testing

ARCDevTools includes automated quality checks via git hooks and GitHub Actions.

**Local testing:**
```bash
make lint          # Run SwiftLint
make format        # Check formatting
make fix           # Apply formatting
```

**Pre-commit hook:**
- Automatically runs on `git commit`
- Formats and lints staged Swift files
- Blocks commit if linting fails

**Pre-push hook:**
- Automatically runs on `git push`
- Runs all tests
- Blocks push if tests fail

---

## 🤝 Contributing

ARCDevTools is an internal tool for ARC Labs Studio. Contributions from team members are welcome.

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines on:
- Git Flow workflow (feature → develop → main)
- Conventional Commits format
- Pull request process
- Code quality standards
- CI/CD automation

**Quick start:**
1. Clone with submodules: `git clone --recurse-submodules https://github.com/arclabs-studio/ARCDevTools.git`
2. Create a feature branch: `feature/your-improvement`
3. Follow the standards defined in [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)
4. Ensure all changes work: test `arc-setup` in a sample project
5. Create a pull request to `develop`

---

## 📚 Documentation

See the [docs/](docs/) directory for detailed guides:

- [Getting Started](docs/getting-started.md) - Installation walkthrough
- [Integration Guide](docs/integration.md) - Detailed integration instructions
- [Configuration](docs/configuration.md) - Customization options
- [CI/CD Guide](docs/ci-cd.md) - GitHub Actions setup
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

---

## 📄 License

MIT License © 2025 ARC Labs Studio

See [LICENSE](LICENSE) for details.

---

## 🔗 Related Resources

- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** - Complete development standards and guidelines (included as submodule)
- **[SwiftLint](https://github.com/realm/SwiftLint)** - A tool to enforce Swift style and conventions
- **[SwiftFormat](https://github.com/nicklockwood/SwiftFormat)** - Code formatting for Swift

---

<div align="center">

Made with 💛 by ARC Labs Studio

</div>
