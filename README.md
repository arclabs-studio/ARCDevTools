# 🛠️ ARCDevTools

![Version](https://img.shields.io/badge/Version-2.5.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS-blue.svg)

**Centralized quality tooling for ARC Labs Studio**

One command installs SwiftLint, SwiftFormat, git hooks, CI/CD workflows, and Claude Code skills into any ARC Labs project.

---

## 🎯 Overview

ARCDevTools standardizes development tooling across all ARC Labs projects. Add it as a git submodule, run the setup script, and your project gets:

- **SwiftLint** — 40+ rules aligned with [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge) standards
- **SwiftFormat** — Consistent formatting (4 spaces, 120 chars, same-line attributes)
- **Git Hooks** — Pre-commit (format + lint) and pre-push (tests)
- **Makefile** — `make lint`, `make format`, `make test`, and more
- **CI/CD Workflows** — GitHub Actions templates for quality, testing, and releases
- **Claude Code Skills** — 11 ARCKnowledge skills + package validator, auto-installed via symlinks

### Supported Project Types

| Type | Detection | Build | Test |
|------|-----------|-------|------|
| **Swift Package** | `Package.swift` present | `swift build` | `swift test` |
| **iOS App** | `.xcodeproj` present | `xcodebuild build` | `xcodebuild test` |

The setup script detects your project type automatically.

---

## 📋 Requirements

- **Swift** 6.0+
- **Xcode** 16.0+ (for iOS apps)
- **Git** 2.30+
- **SwiftLint** and **SwiftFormat** (`brew install swiftlint swiftformat`)

---

## 🚀 Installation

### 1. Add as Submodule

```bash
cd /path/to/your/project
git submodule add https://github.com/arclabs-studio/ARCDevTools
git submodule update --init --recursive
```

The `--recursive` flag is important — it also pulls the nested ARCKnowledge submodule that contains the development standards and Claude Code skills.

### 2. Run Setup

```bash
./ARCDevTools/arcdevtools-setup
```

This copies configs to your project root, installs git hooks, generates a Makefile, and symlinks Claude Code skills. You'll be asked whether to also copy GitHub Actions workflows.

Non-interactive mode for CI:
```bash
./ARCDevTools/arcdevtools-setup --with-workflows   # Include workflows
./ARCDevTools/arcdevtools-setup --no-workflows     # Skip workflows
```

### 3. Commit

```bash
git add .gitmodules ARCDevTools/ .swiftlint.yml .swiftformat Makefile .claude/
git commit -m "chore: integrate ARCDevTools for quality automation"
```

### What Gets Installed

After setup, your project looks like this:

```
YourProject/
├── ARCDevTools/                     ← submodule (this repo)
│   └── ARCKnowledge/               ← nested submodule (standards + skills)
├── .swiftlint.yml                  ← copied from configs/
├── .swiftformat                    ← copied from configs/
├── .git/hooks/pre-commit           ← installed from hooks/
├── .git/hooks/pre-push             ← installed from hooks/
├── Makefile                        ← generated for your project type
├── .github/workflows/              ← copied if you chose workflows
└── .claude/skills/                 ← ARCKnowledge skills (symlinks) + ARCDevTools skills (copied)
```

---

## 📖 Usage

### Makefile Commands

```bash
make help      # Show all available commands
make lint      # Run SwiftLint
make format    # Check formatting (dry-run)
make fix       # Apply SwiftFormat auto-fixes
make setup     # Re-run ARCDevTools setup
make hooks     # Re-install git hooks
make clean     # Clean build artifacts
```

**Swift Packages** also get:
```bash
make build     # swift build
make test      # swift test --parallel
```

**iOS Apps** also get:
```bash
make build SCHEME=MyApp    # xcodebuild build
make test SCHEME=MyApp     # xcodebuild test
```

### Git Hooks

Quality checks run automatically:

- **Pre-commit** — Runs SwiftFormat (auto-fix) and SwiftLint (strict) on staged `.swift` files. Blocks the commit if linting fails.
- **Pre-push** — Runs all tests. Blocks the push if tests fail.

---

## 📐 Code Style

ARCDevTools enforces the code style defined in [ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge). The key settings:

### SwiftFormat

| Setting | Value |
|---------|-------|
| Indentation | 4 spaces |
| Line width | 120 characters |
| Self keyword | Remove when not required |
| Brace style | Same-line (K&R) |
| Wrap arguments | After first (first param on same line) |
| Wrap parameters | After first (first param on same line) |
| Attributes | Always same-line (type, func, stored-var, computed-var, complex) |
| Imports | Grouped, `@testable` at bottom |

### SwiftLint

**40+ opt-in rules** including:

- **Multiline formatting** — `multiline_arguments` and `multiline_parameters` with `first_argument_location: same_line`, plus bracket and chain rules
- **Safety** — `force_unwrapping`, `no_force_cast` (error), `no_force_try` (error)
- **Style** — `implicit_return`, `closure_spacing`, `vertical_whitespace_*_braces`, `yoda_condition`
- **Performance** — `first_where`, `last_where`, `sorted_first_last`, `contains_over_filter_*`

**Custom rules:**

| Rule | Severity | Purpose |
|------|----------|---------|
| `observable_viewmodel` | warning | ViewModels must use `@Observable` |
| `no_force_cast` | error | Use `as?` instead of `as!` |
| `no_force_try` | error | Use proper error handling instead of `try!` |
| `no_empty_line_after_guard` | warning | Clean guard statement formatting |

Full configs: [`configs/swiftlint.yml`](configs/swiftlint.yml) and [`configs/swiftformat`](configs/swiftformat).

---

## 🛠️ Customization

The copied configs (`.swiftlint.yml`, `.swiftformat`) are yours to modify. Your customizations are preserved when updating ARCDevTools — the setup script overwrites them, so commit any local overrides before re-running setup.

For project-specific SwiftLint additions, edit the copied `.swiftlint.yml` directly.

---

## ⚙️ CI/CD

### Xcode Cloud (Recommended for iOS Apps)

ARCDevTools provides `ci_scripts/` templates for [Xcode Cloud](https://developer.apple.com/documentation/xcode/xcode-cloud) — Apple's native CI/CD with 25 free compute hours/month.

During setup, iOS apps are offered interactive installation:

```
Do you want to install Xcode Cloud ci_scripts/? [y/N]:
```

Or non-interactive: `./ARCDevTools/arcdevtools-setup --with-workflows`

**Templates** in [`templates/ci_scripts/`](templates/ci_scripts/):

| Script | When | Purpose |
|--------|------|---------|
| `ci_post_clone.sh` | After clone | Verify `Package.resolved`, install SwiftLint |
| `ci_pre_xcodebuild.sh` | Before each build | Log build context (action, platform, PR/tag) |
| `ci_post_xcodebuild.sh` | After each build | Log results (archive/test paths) |

See the complete setup guide: [`docs/xcode-cloud-setup.md`](docs/xcode-cloud-setup.md)

### GitHub Actions Workflows

Workflows are templates adapted per project type. Choose to install them during setup.

**Core workflows:**

| Workflow | Swift Package | iOS App |
|----------|--------------|---------|
| `quality.yml` | Checks `Sources/`, `Tests/` | Checks project root |
| `tests.yml` | `swift test` (macOS + Linux) | `xcodebuild test` (iOS Simulator) |

**Shared workflows:**
- `enforce-gitflow.yml` — Branch rule enforcement
- `sync-develop.yml` — Auto-sync main to develop
- `release-drafter.yml` — Auto-draft release notes from PRs

**SPM-only:** `docs.yml` (DocC), `validate-release.yml`

> **Billing note:** macOS runners have a 10x billing multiplier on GitHub Actions. ARCDevTools optimizes by running lint/format on Ubuntu. See [docs/ci-cd.md](docs/ci-cd.md) for details.

---

## 🤖 Claude Code Skills

ARCDevTools delivers Claude Code skills from two sources:

### ARCKnowledge Skills (12 skills)

Installed as **symlinks** from `ARCDevTools/ARCKnowledge/.claude/skills/` into your project's `.claude/skills/`. These provide progressive context loading — agents load only the standards they need for the current task.

| Phase | Skills |
|-------|--------|
| **Architecture** | `/arc-swift-architecture`, `/arc-project-setup` |
| **Implementation** | `/arc-presentation-layer`, `/arc-data-layer`, `/arc-tdd-patterns`, `/arc-worktrees-workflow`, `/arc-memory` |
| **Review** | `/arc-final-review`, `/arc-quality-standards`, `/arc-workflow` |
| **Audit** | `/arc-audit` |
| **CI/CD** | `/arc-xcode-cloud` |

For detailed descriptions of each skill and how they interact with other skill sources (Axiom, MCP Cupertino), see [`ARCKnowledge/Skills/skills-index.md`](ARCKnowledge/Skills/skills-index.md).

### ARCDevTools Skills

Installed as **copies** into `.claude/skills/`:

| Skill | Purpose |
|-------|---------|
| `arc-package-validator` | Validates Swift Packages against ARCKnowledge standards (structure, config, docs, quality) |

Run directly: `swift .claude/skills/arc-package-validator/scripts/validate.swift .`

---

## 🔄 Updating

```bash
cd ARCDevTools
git pull origin main
cd ..
git submodule update --recursive
./ARCDevTools/arcdevtools-setup
git add ARCDevTools .swiftlint.yml .swiftformat Makefile
git commit -m "chore(deps): update ARCDevTools to vX.Y.Z"
```

---

## 🏗️ Project Structure

```
ARCDevTools/
├── arcdevtools-setup              # Setup script (Swift)
├── configs/
│   ├── swiftlint.yml              # SwiftLint configuration
│   └── swiftformat                # SwiftFormat configuration
├── hooks/
│   ├── pre-commit                 # Format + lint on commit
│   ├── pre-push                   # Tests on push
│   └── install-hooks.sh           # Hook installer
├── scripts/
│   ├── lint.sh                    # Standalone lint script
│   ├── format.sh                  # Standalone format script
│   ├── setup-github-labels.sh     # GitHub label configuration
│   ├── setup-branch-protection.sh # Branch protection rules
│   └── setup-skills.sh            # Skills installer
├── workflows-spm/                 # CI/CD templates (Swift Packages)
├── workflows-ios/                 # CI/CD templates (iOS Apps)
├── claude-hooks/                  # Claude Code hooks (notifications)
├── templates/                     # GitHub PR template, etc.
├── .claude/skills/                # ARCDevTools-specific skills
│   └── arc-package-validator/
├── ARCKnowledge/                  # Submodule: standards + skills
├── docs/                          # Additional documentation
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## 🤝 Contributing

ARCDevTools is an internal tool for ARC Labs Studio.

1. Clone: `git clone --recurse-submodules https://github.com/arclabs-studio/ARCDevTools.git`
2. Branch: `feature/your-improvement`
3. Test changes by running `arcdevtools-setup` in a sample project
4. PR to `develop`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines.

---

## 🔗 Related

- **[ARCKnowledge](https://github.com/arclabs-studio/ARCKnowledge)** — Development standards and Claude Code skills (included as submodule)
- **[SwiftLint](https://github.com/realm/SwiftLint)** — Swift style enforcement
- **[SwiftFormat](https://github.com/nicklockwood/SwiftFormat)** — Code formatting for Swift

---

MIT License - 2025 ARC Labs Studio
