# Contributing to ARCDevTools

Thank you for contributing to ARCDevTools! This document provides guidelines for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Git Flow](#git-flow)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Testing](#testing)
- [CI/CD Automation](#cicd-automation)
- [Troubleshooting](#troubleshooting)

---

## Code of Conduct

ARCDevTools is an internal tool for ARC Labs Studio. All contributors are expected to:

- Write clean, maintainable, and well-documented code
- Follow established coding standards and best practices
- Be respectful and collaborative in code reviews
- Prioritize quality over speed

---

## Getting Started

### Prerequisites

- **Swift:** 6.0+
- **macOS:** 13.0+
- **Xcode:** 16.0+
- **Tools:** SwiftLint, SwiftFormat

```bash
# Install required tools
brew install swiftlint swiftformat
```

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/arclabs-studio/ARCDevTools.git
cd ARCDevTools

# Checkout develop branch
git checkout develop
git pull origin develop

# Run setup (installs git hooks, configs, etc.)
swift run arc-setup
```

---

## Development Workflow

ARCDevTools follows a **Git Flow** workflow with two main branches:

- **`main`** - Production releases only (protected)
- **`develop`** - Active development (protected)

### Branch Types

1. **Feature branches** - `feature/your-feature-name`
   - For new features or enhancements
   - Branch from: `develop`
   - Merge back to: `develop`

2. **Hotfix branches** - `hotfix/issue-description`
   - For urgent fixes to production
   - Branch from: `main`
   - Merge back to: `main` (then auto-sync to `develop`)

3. **Release branches** - `release/vX.Y.Z` (optional)
   - For release preparation
   - Branch from: `develop`
   - Merge to: `main` and `develop`

---

## Git Flow

### Creating a Feature

```bash
# 1. Start from updated develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/my-new-feature

# 3. Make changes and commit following conventional commits
git add .
git commit -m "feat: add new configuration option"

# 4. Push to remote
git push origin feature/my-new-feature

# 5. Create Pull Request to develop
gh pr create --base develop --title "feat: add new configuration option"
```

### Creating a Hotfix

```bash
# 1. Start from main
git checkout main
git pull origin main

# 2. Create hotfix branch
git checkout -b hotfix/critical-bug-fix

# 3. Fix the issue
git add .
git commit -m "fix: resolve critical bug in setup script"

# 4. Push and create PR to main
git push origin hotfix/critical-bug-fix
gh pr create --base main --title "fix: resolve critical bug in setup script"
```

### Release Process

When `develop` is ready for release:

```bash
# 1. Create PR from develop to main
gh pr create --base main --head develop --title "🚀 Release vX.Y.Z"

# 2. After merge, create and push tag
git checkout main
git pull origin main
git tag -a vX.Y.Z -m "Release vX.Y.Z - description"
git push origin vX.Y.Z

# 3. GitHub Actions will automatically:
#    - Validate the release
#    - Create a release draft
#    - Sync develop with main
```

---

## Commit Guidelines

ARCDevTools follows **[Conventional Commits](https://www.conventionalcommits.org/)** specification.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat** - New feature
- **fix** - Bug fix
- **docs** - Documentation changes
- **style** - Code style changes (formatting, no logic change)
- **refactor** - Code refactoring
- **perf** - Performance improvements
- **test** - Adding or updating tests
- **chore** - Maintenance tasks, dependencies
- **ci** - CI/CD changes
- **build** - Build system changes

### Examples

```bash
# Feature
git commit -m "feat: add SwiftLint rule for logging"

# Bug fix
git commit -m "fix: correct SwiftFormat indentation config"

# Documentation
git commit -m "docs: update installation instructions"

# Breaking change
git commit -m "feat!: change public API structure

BREAKING CHANGE: ARCConfiguration initializer signature changed"
```

### Best Practices

- Use present tense: "add feature" not "added feature"
- Use imperative mood: "move cursor" not "moves cursor"
- Don't capitalize first letter
- No period at the end
- Keep subject line under 72 characters
- Reference issues and PRs in footer: `Closes #123`

---

## Pull Request Process

### Before Creating a PR

1. **Run quality checks locally:**
   ```bash
   make lint          # Run SwiftLint
   make format        # Check formatting
   swift test         # Run all tests
   ```

2. **Update documentation:**
   - Update `CHANGELOG.md` with your changes
   - Update DocC comments if you changed public APIs
   - Update README if needed

3. **Self-review your code:**
   - Remove debug code and console logs
   - Check for commented-out code
   - Verify no hardcoded values
   - Ensure proper error handling

### Creating the PR

1. **Push your branch:**
   ```bash
   git push origin feature/my-feature
   ```

2. **Create PR using GitHub CLI or web UI:**
   ```bash
   gh pr create \
     --base develop \
     --title "feat: descriptive title" \
     --body "See PULL_REQUEST_TEMPLATE"
   ```

3. **Fill out PR template completely:**
   - Description of changes
   - Type of change
   - Testing performed
   - Related issues
   - Screenshots (if UI changes)

### PR Review Checklist

Reviewers will check:

- [ ] Code follows ARC Labs coding standards
- [ ] All tests pass
- [ ] No linting errors or warnings
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Commit messages follow conventional commits
- [ ] No breaking changes (or properly documented)
- [ ] PR targets correct branch (feature → develop, hotfix → main)

### After Approval

- **Do NOT merge yourself** - CI will handle auto-merge if configured
- If CI fails, fix issues and push new commits
- Once merged, delete your feature branch

---

## Code Style

### Swift Style Guidelines

ARCDevTools follows ARC Labs coding standards (see [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)):

**Key Rules:**
- 4 spaces for indentation (no tabs)
- 120 characters max line length
- Omit `self` when not required
- Use `@Observable` for ViewModels
- Protocol-based dependency injection
- Swift Testing framework (not XCTest)

### Pre-commit Hook

The pre-commit hook automatically runs:
1. **SwiftLint** - Enforces code quality rules
2. **SwiftFormat** - Checks code formatting

If checks fail, the commit is blocked. Fix issues and try again.

**Bypass hook (use sparingly):**
```bash
git commit --no-verify -m "message"
```

---

## Testing

ARCDevTools uses the **Swift Testing** framework (not XCTest).

### Running Tests

```bash
# Run all tests
swift test

# Run tests in parallel (faster)
swift test --parallel

# Run specific test
swift test --filter ARCDevToolsTests
```

### Writing Tests

```swift
import Testing
@testable import ARCDevTools

@Suite("ARCDevTools Configuration Tests")
struct ConfigurationTests {

    @Test("SwiftLint config exists")
    func swiftlintConfigExists() {
        #expect(ARCDevTools.swiftlintConfig != nil)
    }

    @Test("SwiftFormat config exists")
    func swiftformatConfigExists() {
        #expect(ARCDevTools.swiftformatConfig != nil)
    }
}
```

### Test Guidelines

- Use descriptive test names with `@Test` attributes
- Use `#expect` instead of `XCTAssert*`
- Group related tests with `@Suite`
- Test both success and failure cases
- Mock dependencies using protocols
- Aim for >80% code coverage

---

## CI/CD Automation

ARCDevTools has comprehensive GitHub Actions automation:

### Workflows

1. **tests.yml** - Runs on all PRs
   - Builds on macOS (Xcode 16) and Linux (Swift 6.0)
   - Runs all tests in parallel
   - Reports test failures

2. **quality.yml** - Runs on all PRs
   - SwiftLint (strict mode)
   - SwiftFormat (lint mode)
   - Markdown link validation
   - Blocks PR if checks fail

3. **docs.yml** - Runs on push to main
   - Generates DocC documentation
   - Deploys to GitHub Pages
   - Archives documentation artifacts

4. **enforce-gitflow.yml** - Runs on all PRs
   - Validates branch naming conventions
   - Ensures `feature/*` → `develop`
   - Ensures `hotfix/*` → `main`
   - Warns on non-conventional commits

5. **sync-develop.yml** - Runs after merge to main
   - Automatically syncs `main` → `develop`
   - Creates issue if conflicts occur
   - Prevents branch divergence

6. **validate-release.yml** - Runs on tag push
   - Validates semver tag format (vX.Y.Z)
   - Checks CHANGELOG.md entry
   - Builds and tests release configuration
   - Creates GitHub release

7. **release-drafter.yml** - Runs on PR merge
   - Automatically generates release notes
   - Categorizes changes by type
   - Suggests next version number
   - Creates draft release

### Branch Protection

**main branch:**
- Requires 1 approval
- Requires all status checks to pass
- Requires linear history
- No force pushes
- No deletions

**develop branch:**
- Requires status checks to pass
- No force pushes
- No deletions

### Status Checks Required

Before merging, these must pass:
- ✅ Build (macOS + Linux)
- ✅ Tests
- ✅ SwiftLint
- ✅ SwiftFormat
- ✅ Markdown links
- ✅ Branch rules

---

## Troubleshooting

### Common Issues

#### "SwiftLint errors in CI but not locally"

**Cause:** Different SwiftLint versions

**Solution:**
```bash
brew upgrade swiftlint
make lint
```

#### "SwiftFormat check fails"

**Cause:** Code not formatted according to standards

**Solution:**
```bash
make fix    # Auto-format code
git add .
git commit --amend --no-edit
git push --force-with-lease
```

#### "Tests pass locally but fail in CI"

**Cause:** Platform differences or missing dependencies

**Solution:**
- Check CI logs for specific error
- Ensure tests don't depend on local files
- Verify Swift version compatibility

#### "Pre-commit hook is slow"

**Cause:** Linting/formatting large codebase

**Solution:**
```bash
# Temporarily disable for quick commits
git commit --no-verify -m "message"

# Or optimize SwiftLint config to exclude unnecessary paths
```

#### "Merge conflict during develop sync"

**Cause:** Divergent changes between main and develop

**Solution:**
1. Check for auto-created GitHub issue
2. Manually resolve conflict:
   ```bash
   git checkout develop
   git pull origin develop
   git merge origin/main
   # Resolve conflicts
   git commit
   git push origin develop
   ```

#### "Release draft not created"

**Cause:** PR missing labels or release-drafter config issue

**Solution:**
- Ensure PRs have appropriate labels (feature, fix, etc.)
- Check `.github/release-drafter.yml` syntax
- Manually trigger workflow: Actions → Release Drafter → Run workflow

### Getting Help

- Check existing issues: https://github.com/arclabs-studio/ARCDevTools/issues
- Review ARCKnowledge for standards: https://github.com/arclabs-studio/ARCKnowledge
- Ask in ARC Labs Studio team channels

---

## Additional Resources

- **[Conventional Commits](https://www.conventionalcommits.org/)** - Commit message format
- **[Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)** - Branching model
- **[Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)** - Swift best practices
- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** - ARC Labs standards

---

**Thank you for contributing to ARCDevTools!** 💛

*Made with care by ARC Labs Studio*
