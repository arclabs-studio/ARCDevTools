# ARCDevTools Documentation

Centralized quality automation and development tooling for ARC Labs Studio.

## Quick Links

- [Getting Started](getting-started.md) - Installation and setup walkthrough
- [Integration Guide](integration.md) - How to integrate ARCDevTools as a Git submodule
- [Configuration](configuration.md) - Customize rules for your project
- [CI/CD Guide](ci-cd.md) - Set up GitHub Actions workflows
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
- [Migration Guide](MIGRATION_V1_TO_V2.md) - Upgrade from v1.x (SPM) to v2.x (submodule)

## Overview

ARCDevTools provides standardized development tooling for ARC Labs projects, including:

- **SwiftLint Configuration** - 40+ linting rules aligned with ARCKnowledge standards
- **SwiftFormat Configuration** - Consistent code formatting across all projects
- **Git Hooks** - Pre-commit and pre-push hooks for automated quality checks
- **GitHub Actions Workflows** - CI/CD templates for quality, testing, and releases
- **Project Setup** - One-command installation script
- **Makefile Generation** - Convenient commands for common tasks

## Installation

```bash
# Add as submodule
git submodule add https://github.com/arclabs-studio/ARCDevTools
git submodule update --init --recursive

# Run setup
./ARCDevTools/arc-setup
```

See [Getting Started](getting-started.md) for detailed installation instructions.

## Usage

After installation, use the generated Makefile:

```bash
make help      # Show all available commands
make lint      # Run SwiftLint
make format    # Check formatting (dry-run)
make fix       # Apply SwiftFormat
make setup     # Re-run ARCDevTools setup
make hooks     # Re-install git hooks
make clean     # Clean build artifacts
```

## Documentation Structure

- **[getting-started.md](getting-started.md)** - Installation and initial setup
- **[integration.md](integration.md)** - Detailed integration guide for different project types
- **[configuration.md](configuration.md)** - How to customize SwiftLint, SwiftFormat, and git hooks
- **[ci-cd.md](ci-cd.md)** - GitHub Actions workflow templates and setup
- **[troubleshooting.md](troubleshooting.md)** - Solutions to common problems
- **[MIGRATION_V1_TO_V2.md](MIGRATION_V1_TO_V2.md)** - Upgrade guide from SPM to submodule

## Related Resources

- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** - Complete development standards and guidelines (included as submodule)
- **[SwiftLint](https://github.com/realm/SwiftLint)** - A tool to enforce Swift style and conventions
- **[SwiftFormat](https://github.com/nicklockwood/SwiftFormat)** - Code formatting for Swift

## Support

- Check [Troubleshooting](troubleshooting.md) for common issues
- Review [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge) for development standards
- Open an issue on [GitHub](https://github.com/arclabs-studio/ARCDevTools/issues)

---

**ARC Labs Studio** - Made with 💛
