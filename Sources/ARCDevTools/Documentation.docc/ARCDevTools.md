# ``ARCDevTools``

Centralized quality automation and development tooling for ARC Labs Studio.

## Overview

ARCDevTools is a Swift package that provides standardized development tooling for all ARC Labs projects. It bundles SwiftLint and SwiftFormat configurations, pre-commit hooks, code templates, and automation scripts to ensure consistency and reduce configuration drift across the entire ecosystem.

### Key Features

- **Pre-configured SwiftLint** - Comprehensive linting rules aligned with ARC Labs standards
- **Pre-configured SwiftFormat** - Automatic code formatting with consistent style
- **Git Hooks** - Automated quality checks on commit
- **Project Setup** - One-command setup for new and existing projects
- **Makefile Generation** - Convenient commands for common tasks
- **Code Templates** - Scaffolding for common patterns

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Integration>
- ``ARCDevTools/version``
- ``ARCDevTools/bundle``

### Configuration Resources

- ``ARCDevTools/swiftlintConfig``
- ``ARCDevTools/swiftformatConfig``
- ``ARCDevTools/scriptsDirectory``
- ``ARCDevTools/templatesDirectory``

### Utilities

- ``ARCDevTools/copyResource(from:to:)``
- ``ARCDevTools/makeExecutable(_:)``

### Configuration Model

- ``ARCConfiguration``

### Articles

- <doc:GettingStarted>
- <doc:Integration>
- <doc:Configuration>
- <doc:CICD>
- <doc:Troubleshooting>

## See Also

- [ARCAgentsDocs](https://github.com/arclabs-studio/ARCAgentsDocs) - Complete development standards and guidelines
- [GitHub Repository](https://github.com/arclabs-studio/ARCDevTools)
