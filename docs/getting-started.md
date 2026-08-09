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
- **Git 2.30+** for submodule support

## Installation Steps

### Step 1: Add ARCDevTools as Submodule

Navigate to your project root and add ARCDevTools as a Git submodule:

```bash
cd /path/to/your/project
git submodule add https://github.com/arclabs-studio/ARCDevTools
git submodule update --init --recursive
```

This creates an `ARCDevTools/` directory in your project with all configuration files and scripts.

**For existing clones:**

If someone clones your project, they need to initialize the submodules:

```bash
git clone --recurse-submodules https://github.com/your-org/your-project
# Or if already cloned:
git submodule update --init --recursive
```

### Step 2: Run Setup

Navigate to your project root directory and run the setup script:

```bash
cd /path/to/your/project
./ARCDevTools/arcdevtools-setup
```

The setup tool will:

1. ✅ Copy `.arc-tool-versions` (pinned SwiftLint/SwiftFormat versions)
2. ✅ Copy `.swiftlint.yml` configuration to your project
3. ✅ Copy `.swiftformat` configuration to your project
4. ✅ Install pre-commit and pre-push git hooks (if `.git/` exists)
5. ✅ Generate a `Makefile` with useful commands
6. ✅ Optionally copy GitHub Actions workflows (you'll be asked)

### Step 3: Install the Pinned Linters

```bash
make tools
```

This downloads the exact SwiftLint and SwiftFormat versions pinned in
`.arc-tool-versions` into `.arc-tools/bin` (gitignored). Do **not**
`brew install swiftlint` — brew has no versioned formula, so it drifts to
whatever is latest and your local results stop matching CI. Re-run
`make tools` whenever the pin changes; the git hooks warn you if your version
differs.

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

- Read [Integration Guide](integration.md) to learn how to customize your setup
- Check [Configuration](configuration.md) to adjust rules for your project
- See [CI/CD Guide](ci-cd.md) to set up GitHub Actions workflows
- See [Troubleshooting](troubleshooting.md) if you encounter any issues

## Updating ARCDevTools

To get the latest configurations and scripts:

```bash
cd ARCDevTools
git pull origin main
cd ..
./ARCDevTools/arcdevtools-setup  # Re-run setup to update configs
git add ARCDevTools
git commit -m "chore: update ARCDevTools to latest version"
```

## See Also

- [Integration Guide](integration.md) - Detailed integration instructions
- [Configuration](configuration.md) - Customization options
- [CI/CD Guide](ci-cd.md) - GitHub Actions setup
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
