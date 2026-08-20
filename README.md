# 🛠️ ARCDevTools

![Version](https://img.shields.io/badge/Version-2.5.0-blue.svg)
![License](https://img.shields.io/badge/License-PolyForm%20Noncommercial%201.0.0-orange.svg)
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

> The `make build` / `make test` targets shell out to `swift` / `xcodebuild`
> for CI and headless use. For interactive build, test, and diagnostics, prefer
> the Xcode MCP (see the `arc-mcp-xcode` skill).

---

## 📋 Requirements

- **Swift** 6.0+
- **Xcode** 16.0+ (for iOS apps)
- **Git** 2.30+
- **SwiftLint** and **SwiftFormat** — installed by `make tools`, not Homebrew
  (see [Pinned tool versions](#-pinned-tool-versions))

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
git add .gitmodules ARCDevTools/ .swiftlint.base.yml .swiftlint.yml .swiftformat Makefile .claude/
git commit -m "chore: integrate ARCDevTools for quality automation"
```

### What Gets Installed

After setup, your project looks like this:

```
YourProject/
├── ARCDevTools/                     ← submodule (this repo)
│   └── ARCKnowledge/               ← nested submodule (standards + skills)
├── .arc-tool-versions              ← pinned SwiftLint/SwiftFormat versions (auto-refreshed)
├── .arc-tools/bin/                 ← pinned linter binaries (gitignored, `make tools`)
├── .swiftlint.base.yml             ← studio rules (auto-refreshed every run)
├── .swiftlint.yml                  ← project-owned: `included:` paths + local tweaks
├── .swiftformat                    ← project-owned (kept on re-run)
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
make tools     # Install the pinned SwiftLint/SwiftFormat into .arc-tools/
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

Both hooks use the pinned linters and warn loudly if your local version differs
from the pin.

---

## 📌 Pinned Tool Versions

SwiftLint and SwiftFormat are pinned to exact versions in
[`configs/tool-versions`](configs/tool-versions), copied into every project as
`.arc-tool-versions` (studio-owned, refreshed on every setup run).

```bash
make tools     # installs the pinned versions into .arc-tools/bin (gitignored)
```

Everything resolves that pin through
[`scripts/tool-env.sh`](scripts/tool-env.sh): git hooks, `make lint`,
`make format`, GitHub Actions, and Xcode Cloud. Local results therefore match
CI exactly.

### Why not Homebrew?

Homebrew has no versioned formula for either tool, so `brew install swiftlint`
resolves to whatever is latest that day. That produced the failure mode this
replaced: developer machines sat on an old SwiftLint, SPM CI installed the
newest via brew, and iOS CI used `norio-nomura/action-swiftlint` — whose
version tag pins the *action*, not the linter behind it (a moving Docker tag).
Three different linters, one `--strict` gate. PRs that were green locally
failed in CI, most often with `superfluous_disable_command` errors: a
`// swiftlint:disable` comment an older version required, that a newer version
flags as unnecessary.

`.arc-tools/` holds machine-specific binaries and is gitignored. The pin itself
is committed, so the version is reviewed like any other change.

### Bumping a version

1. Edit `SWIFTLINT_VERSION` / `SWIFTFORMAT_VERSION` in `configs/tool-versions`.
2. Run `./ARCDevTools/scripts/install-tools.sh` and `make lint format`.
3. Fix any new violations, commit, tag a release.
4. Consumers pick it up on their next submodule update + `arcdevtools-setup`,
   then run `make tools`.

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

Full configs: [`configs/swiftlint.base.yml`](configs/swiftlint.base.yml), [`configs/swiftlint.starter.yml`](configs/swiftlint.starter.yml), and [`configs/swiftformat`](configs/swiftformat).

---

## 🛠️ Customization

ARCDevTools splits SwiftLint config into two files with different owners:

| File | Owner | Refresh policy |
|------|-------|----------------|
| `.swiftlint.base.yml` | **Studio** | Overwritten on every `arcdevtools-setup` run. Do not edit. |
| `.swiftlint.yml`      | **Project** | Generated once if absent. Kept on re-run unless `--force`. |
| `.swiftformat`        | **Project** | Generated once if absent. Kept on re-run unless `--force`. |

`.swiftlint.yml` references the base via `parent_config:` and carries the
project-specific `included:` paths plus any local rule tweaks. This means
**studio rule updates flow automatically** when you bump the ARCDevTools
submodule — without ever rewriting your `included:` paths.

```yaml
# .swiftlint.yml (project-owned)
parent_config: .swiftlint.base.yml

included:
  - MyApp/MyApp
  - MyApp/MyAppTests

# Optional project-local overrides:
line_length:
  warning: 140
```

### Restoring studio defaults

To reset `.swiftlint.yml` or `.swiftformat` to the shipped template:

```bash
./ARCDevTools/arcdevtools-setup --force
```

`--force` overwrites the project-owned files only. `.swiftlint.base.yml`
refreshes on every run regardless.

### Migrating from a flat `.swiftlint.yml`

If your project predates the split (pre-v1.2.0), the safest path:

1. Note your current `included:` paths.
2. Delete `.swiftlint.yml` and re-run `./ARCDevTools/arcdevtools-setup` —
   the new starter is generated.
3. Edit the new `.swiftlint.yml` and replace the example `included:` with
   your project's paths.
4. Move any project-specific rule overrides from the old file into the new
   `.swiftlint.yml` (below `parent_config:`).

Or convert manually: keep your `.swiftlint.yml`, replace the top with
`parent_config: .swiftlint.base.yml`, drop the studio rule blocks (they
live in the base now), and keep your `included:` + local tweaks.

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
- `validate-pr-title.yml` — Conventional Commits check on PR titles

**Not templates:** `docs.yml` and `validate-release.yml` also live in `workflows-spm/`, but they are ARCDevTools' own CI — `docs.yml` hardcodes `xcodebuild -scheme ARCDevTools` and `validate-release.yml` builds `--product arcdevtools-setup`. Setup never copies them; in a consumer project they could only fail.

**Projects with their own CI**

If `.github/workflows/` already contains a workflow ARCDevTools did not generate — a hand-written `ci.yml`, or a `quality.yml` the project has taken over — setup refreshes only the workflows it generated and adds nothing new. Piling the template set next to hand-written CI produces duplicate lint and build jobs plus gates the project never opted into.

Ownership is judged by the `# ARCDevTools Workflow Template` header, not the filename, so a file you take over is never overwritten. To install the full set regardless:

```bash
./ARCDevTools/arcdevtools-setup --with-workflows --all-workflows
```

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
git add ARCDevTools .swiftlint.base.yml Makefile
# Note: .swiftlint.yml and .swiftformat are project-owned (only re-stage if you edited them).
git commit -m "chore(deps): update ARCDevTools to vX.Y.Z"
```

---

## 🏗️ Project Structure

```
ARCDevTools/
├── arcdevtools-setup              # Setup script (Swift)
├── configs/
│   ├── swiftlint.base.yml         # Studio SwiftLint rules (refreshed every run)
│   ├── swiftlint.starter.yml      # Project-owned starter (parent_config + included:)
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

**PolyForm Noncommercial License 1.0.0** © 2025–2026 ARC Labs Studio.

Source-available. Free for non-commercial use (research, study, hobby, evaluation). **Commercial use requires a separate license** — contact `arclabs.studio@gmail.com`.

ARC Labs Studio's own commercial products are covered by an internal use grant — see [INTERNAL-USE.md](INTERNAL-USE.md).

See [LICENSE](LICENSE) for the full license text.
