# Troubleshooting

Common issues and solutions when using ARCDevTools.

## Overview

This guide covers common problems you might encounter when using ARCDevTools and how to resolve them.

## Installation Issues

### SwiftLint or SwiftFormat Not Found

**Problem:** Running `make lint` or `make format` shows "command not found"

**Solution:**

```bash
# Install the required tools
brew install swiftlint swiftformat

# Verify installation
which swiftlint
which swiftformat

# Check versions
swiftlint version
swiftformat --version
```

### arc-setup Command Not Found

**Problem:** `swift run arc-setup` fails with "no executable product"

**Solution:**

1. Verify ARCDevTools is properly added to your `Package.swift`
2. Run `swift package resolve` to fetch dependencies
3. Check that you're in the correct directory (project root)

```bash
# Resolve dependencies
swift package resolve

# Try again
swift run arc-setup
```

### Permission Denied on Pre-commit Hook

**Problem:** Git hook fails with "Permission denied"

**Solution:**

The pre-commit hook needs executable permissions:

```bash
chmod +x .git/hooks/pre-commit

# Verify
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x
```

## Configuration Issues

### SwiftLint Reports "No lintable files"

**Problem:** SwiftLint can't find any Swift files

**Solution:**

Check your `.swiftlint.yml` configuration:

```yaml
# Ensure included paths are correct
included:
  - Sources
  - Tests

# Check excluded paths aren't too broad
excluded:
  - .build
  - DerivedData
```

### SwiftFormat Changes Nothing

**Problem:** `make fix` runs but no files are formatted

**Solution:**

1. Check that `.swiftformat` file exists in project root
2. Verify exclusion patterns aren't too broad
3. Run with verbose output:

```bash
swiftformat --config .swiftformat --verbose .
```

### Rules Seem to Be Ignored

**Problem:** SwiftLint doesn't enforce expected rules

**Solution:**

Verify configuration hierarchy:

```bash
# Check which config file is being used
swiftlint lint --config .swiftlint.yml --verbose

# Make sure parent_config points to the right file
# In your .swiftlint.yml:
parent_config: .swiftlint.yml  # ← Must be correct path
```

## Build and Runtime Issues

### Build Fails with "Module Not Found"

**Problem:** `import ARCDevTools` causes compilation error

**Solution:**

ARCDevTools should NOT be added to target dependencies:

```swift
// ❌ Wrong
.target(
    name: "YourTarget",
    dependencies: ["ARCDevTools"]  // Don't do this
)

// ✅ Correct
.target(
    name: "YourTarget",
    dependencies: []  // ARCDevTools is build-time only
)
```

### Bundle Resources Not Found

**Problem:** `ARCDevTools.swiftlintConfig` returns `nil`

**Solution:**

This usually happens during development. Ensure:

1. Resources are properly bundled in `Package.swift`:

```swift
.target(
    name: "ARCDevTools",
    dependencies: [],
    resources: [
        .copy("Resources")  // ← Must be present
    ]
)
```

2. Run a clean build:

```bash
swift package clean
swift build
```

## Git Hook Issues

### Pre-commit Hook Runs on Every File

**Problem:** Hook takes too long because it checks all files

**Solution:**

Modify `.git/hooks/pre-commit` to only check staged files:

```bash
#!/bin/bash

# Get list of staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep ".swift$")

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# Run SwiftLint only on staged files
echo "$STAGED_FILES" | xargs swiftlint lint --config .swiftlint.yml --quiet

exit $?
```

### Hook Blocks Commit on Legacy Code

**Problem:** Pre-commit hook fails on existing violations

**Solution:**

**Option 1:** Fix the violations (preferred)

```bash
# Auto-fix what's possible
make fix

# Review and fix manually
make lint
```

**Option 2:** Bypass for urgent commits (use sparingly)

```bash
git commit --no-verify -m "Urgent fix"
```

**Option 3:** Gradually adopt stricter rules

```yaml
# .swiftlint.yml
parent_config: .swiftlint.yml

# Temporarily disable problematic rules
disabled_rules:
  - line_length  # Re-enable once fixed
```

## Performance Issues

### SwiftLint is Very Slow

**Problem:** Linting takes several minutes

**Solutions:**

1. **Exclude generated code and dependencies:**

```yaml
excluded:
  - .build
  - DerivedData
  - Pods
  - Carthage
  - Generated
  - "**/*.generated.swift"
```

2. **Disable analyzer rules** (they're slower):

```yaml
# Comment out analyzer rules for faster local development
# analyzer_rules:
#   - unused_import
#   - unused_declaration
```

3. **Use cached mode:**

```bash
swiftlint lint --cache-path .swiftlint-cache
```

### SwiftFormat Hangs

**Problem:** SwiftFormat seems to freeze

**Solution:**

Check for circular symlinks or very large files:

```bash
# Find large Swift files
find . -name "*.swift" -size +100k

# Run on specific directory
swiftformat Sources/ --verbose
```

## Integration Issues

### Xcode Shows Different Warnings

**Problem:** Xcode warnings don't match `make lint` output

**Solution:**

Xcode needs to be configured to use the same SwiftLint:

1. Add Run Script Phase in Build Phases:

```bash
if which swiftlint >/dev/null; then
    swiftlint lint --config .swiftlint.yml
else
    echo "warning: SwiftLint not installed"
fi
```

2. Ensure the script runs before "Compile Sources"

### CI/CD Pipeline Failures

**Problem:** Tests pass locally but fail in CI

**Solutions:**

1. **Ensure tools are installed in CI:**

```yaml
# .github/workflows/quality.yml
- name: Install Tools
  run: |
    brew install swiftlint swiftformat
```

2. **Use strict mode in CI:**

```bash
swiftlint lint --strict  # Treats warnings as errors
```

3. **Pin tool versions:**

```yaml
- name: Install Tools
  run: |
    brew install swiftlint@0.52.0
    brew install swiftformat@0.50.0
```

## Getting Help

If you encounter issues not covered here:

1. **Check the logs:** Run commands with `--verbose` flag
2. **Verify versions:** Ensure you're using compatible tool versions
3. **Review ARCAgentsDocs:** Check for updated guidance
4. **Ask the team:** Consult other ARC Labs developers
5. **File an issue:** Report bugs on GitHub

## Common Error Messages

### "Configuration file not found"

```bash
# Ensure you're in the project root
cd /path/to/your/project

# Verify config files exist
ls -la .swiftlint.yml .swiftformat

# Re-run setup if needed
swift run arc-setup
```

### "Unsupported Swift version"

```bash
# Update Swift and Xcode
xcode-select --install

# Or use specific Swift toolchain
xcrun --toolchain swift swift --version
```

### "Unknown rule identifier"

Some SwiftLint rules might not be available in older versions:

```bash
# Check available rules
swiftlint rules

# Update SwiftLint
brew upgrade swiftlint

# Or disable the unknown rule temporarily
disabled_rules:
  - unknown_rule_name
```

## See Also

- <doc:GettingStarted>
- <doc:Configuration>
- [SwiftLint Documentation](https://github.com/realm/SwiftLint)
- [SwiftFormat Documentation](https://github.com/nicklockwood/SwiftFormat)
