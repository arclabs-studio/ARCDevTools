# Configuration and Customization

Customize ARCDevTools to fit your project's specific needs.

## Overview

While ARCDevTools provides sensible defaults aligned with ARC Labs standards, you can customize configurations to meet specific project requirements. This guide covers common customization scenarios.

## SwiftLint Customization

### Inheriting from ARCDevTools

Create a `.swiftlint.yml` file in your project root to extend or override ARCDevTools rules:

```yaml
# Inherit base configuration from ARCDevTools
parent_config: .swiftlint.yml

# Disable specific rules for your project
disabled_rules:
  - line_length  # Example: if you need longer lines
  - force_cast   # Example: if you have legacy code

# Add project-specific custom rules
custom_rules:
  my_custom_rule:
    name: "My Custom Rule"
    regex: "specific_pattern"
    message: "Use the approved pattern instead"
    severity: warning
```

### Adjusting Rule Thresholds

Customize length and complexity thresholds:

```yaml
parent_config: .swiftlint.yml

# Override specific rule configurations
line_length:
  warning: 140
  error: 160

type_body_length:
  warning: 400
  error: 600

function_body_length:
  warning: 60
  error: 100
```

### Adding Project-Specific Rules

```yaml
parent_config: .swiftlint.yml

custom_rules:
  no_hardcoded_api_keys:
    name: "No Hardcoded API Keys"
    regex: 'APIKey\s*=\s*"[A-Za-z0-9]+"'
    message: "Don't hardcode API keys. Use environment variables"
    severity: error

  required_view_documentation:
    name: "Views Must Have Documentation"
    regex: 'struct\s+\w+View\s*:\s*View\s*\{'
    message: "All views must have documentation comments"
    severity: warning
```

## SwiftFormat Customization

### Creating a Custom Format File

Create a `.swiftformat` file in your project root:

```bash
# Inherit most settings from ARCDevTools
# Then override specific options

# Use 2-space indentation instead of 4
--indent 2

# Different line width
--maxwidth 100

# Keep explicit self (if your team prefers it)
--self insert
```

### Excluding Files or Directories

Add exclusion patterns:

```bash
# Exclude generated code
--exclude Generated,Pods,.build

# Exclude specific files
--exclude **/Migrations/*.swift
```

## Git Hooks Customization

### Modifying the Pre-commit Hook

The pre-commit hook is located at `.git/hooks/pre-commit`. You can edit it to customize behavior:

```bash
#!/bin/bash

# Run SwiftLint
echo "🔍 Running SwiftLint..."
swiftlint lint --config .swiftlint.yml --strict

# Run SwiftFormat (check only)
echo "🎨 Checking formatting..."
swiftformat --config .swiftformat --lint .

# Add custom checks
echo "🧪 Running custom checks..."
# Your custom validation here

exit 0
```

### Disabling Hooks Temporarily

For urgent commits where hooks would block you:

```bash
git commit --no-verify -m "Urgent fix"
```

**Use sparingly!** Bypassing hooks can introduce quality issues.

## Makefile Customization

The generated `Makefile` can be edited to add project-specific commands:

```makefile
# ARCDevTools Makefile
# Generated automatically - Edit as needed

.PHONY: help lint format fix setup clean test build

help:
	@echo "Available commands:"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Check formatting"
	@echo "  make fix       - Apply formatting"
	@echo "  make test      - Run tests"
	@echo "  make build     - Build project"

lint:
	swiftlint lint --config .swiftlint.yml

format:
	swiftformat --config .swiftformat --lint .

fix:
	swiftformat --config .swiftformat .

# Add custom commands
test:
	swift test

build:
	swift build

clean:
	rm -rf .build DerivedData
```

## ARCConfiguration Model

Use ``ARCConfiguration`` for programmatic configuration:

```swift
import ARCDevTools

// Create custom configuration
var config = ARCConfiguration.default

// Modify lint rules
config.lintRules.warningThreshold = 20
config.lintRules.errorThreshold = 100

// Modify format rules
config.formatRules.indent = 2
config.formatRules.maxWidth = 100

// Disable features
config.enablePreCommitHooks = false
config.autoFormat = false

// Save to file
let configURL = URL(fileURLWithPath: ".arc-config.json")
try config.save(to: configURL)

// Load later
let loadedConfig = ARCConfiguration.load(from: configURL)
```

## Environment-Specific Configuration

### Development vs Production

You can maintain different configurations for different environments:

```bash
# .swiftlint.dev.yml - More lenient for development
parent_config: .swiftlint.yml

disabled_rules:
  - print_statement  # Allow prints during development
  - force_unwrapping # Allow for prototyping

# .swiftlint.prod.yml - Strict for production
parent_config: .swiftlint.yml

opt_in_rules:
  - explicit_self
  - missing_docs
```

Then use the appropriate config:

```bash
# Development
swiftlint lint --config .swiftlint.dev.yml

# Production / CI
swiftlint lint --config .swiftlint.yml --strict
```

## Best Practices

### When to Customize

**Good reasons to customize:**
- Legacy codebase with different conventions
- Project-specific domain requirements
- Gradual adoption of stricter rules
- Framework/library-specific patterns

**Poor reasons to customize:**
- Personal preference over team standards
- Avoiding fixing legitimate issues
- Working around technical debt
- Inconsistency with other ARC Labs projects

### Maintaining Consistency

When customizing:

1. **Document your changes** - Add comments explaining why rules were modified
2. **Keep changes minimal** - Only override what's necessary
3. **Align with ARCKnowledge** - Stay close to ARC Labs standards
4. **Team agreement** - Discuss customizations with your team
5. **Version control** - Track configuration changes in git

## See Also

- ``ARCConfiguration``
- <doc:GettingStarted>
- <doc:Troubleshooting>
