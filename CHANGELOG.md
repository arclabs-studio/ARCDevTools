# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [2.15.0] - 2026-08-10

### Fixed

- **Setup copied ARCDevTools' own CI into consumer projects.** `docs.yml` and `validate-release.yml` sit in `workflows-spm/`, so setup treated them as templates — but `docs.yml` hardcodes `xcodebuild -scheme ARCDevTools` and `validate-release.yml` builds `--product arcdevtools-setup`. Every project that received them got a workflow that can only fail. They trigger on pushes to `main` and on tags rather than on pull requests, which is why the breakage never surfaced in PR checks. Setup no longer copies either; they remain in place as ARCDevTools' own workflows.
- **Setup piled the whole template set onto projects that maintain their own CI.** Re-running it in a repo with a hand-written `ci.yml` added eight template workflows beside it: duplicate lint and build jobs, plus gates the project never opted into (`release-drafter.yml` fails by construction on a feature branch, since its config must live on the default branch). Such projects now get only their existing ARCDevTools-generated workflows refreshed.

  Ownership is decided by the `# ARCDevTools Workflow Template` header rather than the filename, so a `quality.yml` a project has taken over counts as project-owned and is never overwritten. `--all-workflows` installs the full set regardless.

### Added

- **`--all-workflows` flag** — installs the complete template workflow set even in a project that owns its CI. Off by default.

### Changed

- **ARCKnowledge submodule → v2.16.0.** Brings the dead-link cleanup (30 → 0, verified with the same `markdown-link-check` config ARC CI uses) and the `arc-testflight` agent alignment with the tag-push Xcode Cloud pipeline. Also the first ARCKnowledge tag containing the `AGENTS.md` Xcode Tooling Policy section and the `Quality/api-keys.md` standard, which had shipped to `main` untagged.
- **`arcdevtools-setup` → 1.4.0.**

---

## [2.14.5] - 2026-08-10

### Fixed
- **`arc-package-validator` linked ARCKnowledge docs with a broken relative path.** `../../ARCKnowledge/...` from `.claude/skills/arc-package-validator/` resolves to `.claude/ARCKnowledge/...` — wrong in this repo, and wrong again in consumer projects, where the skill is copied to `.claude/skills/` while ARCKnowledge sits under a submodule path that varies per project. The `Validate Markdown Links` job flagged all three as dead in every repo that picked up the skill. Now absolute GitHub URLs.

---

## [2.14.4] - 2026-08-10

### Fixed
- **Pre-commit hook aborted on staged files under ignored paths.** The hook re-stages files after SwiftFormat with `git add`, which refuses paths matched by `.gitignore`. Repos that ignore `.claude/skills/` while tracking the ARCDevTools skills copied inside it could not commit at all — `set -e` turned the refusal into a hook failure. Now uses `git add -f`; the files were already staged, so they are already tracked.

---

## [2.14.3] - 2026-08-10

### Fixed
- **Symlinks from earlier setup runs were never gitignored.** v2.14.1 fixed the `.gitignore` updaters to append missing entries, but they are only called with the symlinks created during the current run — anything linked by a previous run hits the `already exists` guard first. Projects whose `.gitignore` predates a given skill or agent therefore never received the entry, no matter how often setup ran. Pre-existing entries are now included when the destination is a symlink; copied ARCDevTools skills are still left tracked.

---

## [2.14.2] - 2026-08-10

### Fixed
- **`make fix` reformatted the ARCDevTools submodule.** `configs/swiftformat` only excluded build directories, so `swiftformat --config .swiftformat .` walked into the submodule and rewrote the tooling repo's own sources, leaving a `-dirty` submodule pointer in the consumer project. Both configs now exclude `ARCDevTools`, `Tools/ARCDevTools` (the nested layout) and `.arc-tools`. `.swiftformat` is project-owned, so existing projects need the `--exclude` line updated by hand.

---

## [2.14.1] - 2026-08-10

### Fixed
- **Skills and agents added after the first setup run were never gitignored.** `updateGitignoreWithSkills` / `updateGitignoreWithAgents` returned early once their section header existed, so the list was written once and never extended. Consumer projects accumulated untracked symlinks on every ARCKnowledge update (four in ARCPurchasing on the v2.14.0 bump). Both now append only the missing entries, inserted under the existing header.

---

## [2.14.0] - 2026-08-10

### Added
- **`configs/tool-versions`** — single source of truth pinning SwiftLint (`0.65.0`) and SwiftFormat (`0.62.1`). Copied into every project as `.arc-tool-versions` (studio-owned, refreshed on every setup run).
- **`scripts/install-tools.sh`** — installs the pinned linters from official release binaries into `<repo>/.arc-tools/bin` (gitignored). macOS universal + Linux x86_64/arm64 (statically linked SwiftLint, so no Swift toolchain needed on bare CI images). Idempotent.
- **`scripts/tool-env.sh`** — sourced resolver used by hooks and scripts. Prefers `.arc-tools/bin`, falls back to PATH, and warns when the local version differs from the pin.
- **`make tools`** — new Makefile target that runs `install-tools.sh`.
- **`scripts/key-obfuscator.swift`** — codegen for light obfuscation of client-public keys; emits a `[UInt8]` literal reconstructed at runtime via `ARCStorage.ConfigurationValue.deobfuscated(_:)`.
- **ARCKnowledge: `Quality/api-keys.md`** — client secrets & API keys standard (real-secret vs client-public decision tree, xcconfig → Info.plist → `ConfigurationValue`, optional obfuscation, provider key restrictions). Wired into the `arc-quality-standards` skill.
- **`configs/swiftlint.base.yml`** — studio-owned SwiftLint rule set, refreshed unconditionally on every `arcdevtools-setup` run. Carries `disabled_rules` / `opt_in_rules` / `analyzer_rules` / rule configs / `custom_rules` / reporter only — no `included:` paths.
- **`configs/swiftlint.starter.yml`** — thin project-owned starter that references the base via `parent_config:` and declares the project's `included:` paths. Generated as `.swiftlint.yml` only if absent.
- **`arcdevtools-setup --force` / `-f`** — opt-in flag to overwrite project-owned `.swiftlint.yml` and `.swiftformat`. Default behavior now preserves them.

### Fixed
- **SwiftLint version drift broke PR CI.** Three different linter versions were in play at once: dev machines (whatever brew installed months ago, e.g. `0.49.1`), SPM CI (`brew install swiftlint` = always latest, `0.65.0`), and iOS CI (`norio-nomura/action-swiftlint@3.2.1`, whose tag pins the *action* while the image behind it — `norionomura/swiftlint:swift-5` — is a moving tag). Under `swiftlint lint --strict` this produced PRs that were green locally and red in CI, most visibly `superfluous_disable_command` errors where a newer SwiftLint no longer needs a `// swiftlint:disable` an older one required (observed in ARCPurchasing PR #15). All install paths now resolve the pinned version from `.arc-tool-versions`.
- **Hardcoded `ARCDevTools/` submodule path.** Generated Makefiles, copied workflows and `ci_scripts` assumed the submodule sits at `ARCDevTools/`; FavRes-iOS nests it at `Tools/ARCDevTools`, where the new `make tools` target and the pinned-linter CI steps would have pointed at a nonexistent path. `arcdevtools-setup` now resolves the real location and rewrites it in everything it generates. Git hooks locate `tool-env.sh` with a depth-limited search instead of hardcoding it — previously they fell back to unpinned PATH binaries in those projects, reintroducing the drift. Also fixes the pre-existing `make setup` / `make hooks` targets, which had the same assumption.

### Changed
- **`workflows-spm/quality.yml`** — replaced `brew install swiftlint` / `brew install swiftformat` with the pinned installer plus an `actions/cache` step keyed on `.arc-tool-versions`. SwiftFormat now lints against the project's own `.swiftformat` instead of `ARCDevTools/configs/swiftformat`, so project overrides apply and CI matches the git hooks.
- **`workflows-ios/quality.yml`** — dropped `norio-nomura/action-swiftlint` (unmaintained, moving image tag) and the hardcoded SwiftFormat `0.54.6` download; both tools now come from the pinned installer with caching.
- **`templates/ci_scripts/ci_post_clone.sh`** — installs the pinned SwiftLint and symlinks it into `/usr/local/bin` so Xcode Cloud build phases calling bare `swiftlint` get the pinned binary.
- **Git hooks, `scripts/lint.sh`, `scripts/format.sh`, `scripts/pr-ready.sh`** — run the pinned binaries via `tool-env.sh` and warn on version drift instead of silently using whatever is on PATH.
- **`arc-package-validator`** — resolves `.arc-tools/bin` before PATH; "not installed" fixes now say `make tools`, not `brew install`.
- **`arcdevtools-setup` config contract** — split between studio-owned and project-owned files. `.swiftlint.base.yml` refreshes on every run (rule updates flow studio-wide). `.swiftlint.yml` and `.swiftformat` are project-owned: generated once if absent, kept untouched on re-run unless `--force`. Fixes the long-standing bug where re-running setup wiped per-project `included:` paths (FavRes-iOS regression `cf744bd8` / FVRS-252). Setup script bumped to `1.3.0`, which also ships `.arc-tool-versions` and gitignores `.arc-tools/`.
- **`configs/swiftlint.yml` removed** — replaced by `swiftlint.base.yml` + `swiftlint.starter.yml`. Consumer projects re-running setup keep their existing `.swiftlint.yml`. To adopt the split, delete `.swiftlint.yml` and re-run setup (or run `--force`), then edit the new `included:` to match your layout. See README → "Customization" for the manual conversion path.
- **Pre-push hook** — no longer runs tests. Now runs SwiftLint (strict) and SwiftFormat (`--lint`) only; `xcodebuild test` / `swift test` were slow and environment-fragile (SPM resolution failures blocked pushes). Test gating stays in CI.
- **PR title standard** — adopted `[CATEGORY][TICKET-ID] Description` (category mandatory: `FEATURE`/`BUGFIX`/`HOTFIX`/`DOCS`/`CHORE`; ticket optional). `validate-pr-title.yml`, the `arc-pr-publisher` / `arc-release-orchestrator` agents, and the `arc-workflow` skill docs were updated; bare conventional-commits titles are no longer accepted.
- **Xcode tooling docs** — instructional snippets that told Claude/devs to run `xcodebuild` locally now point to the Xcode MCP (`arc-mcp-xcode` skill) as the preferred interactive path; CI workflows and Xcode Cloud scripts are unchanged.

---

## [2.13.1] - 2026-03-28

### Changed
- **ARCKnowledge submodule** updated to v2.13.1 (12 new agents, 3 new skills, Monetization section, swift-design-principles, localization standards)

---

## [2.13.0] - 2026-03-25

### Changed
- **ARCKnowledge submodule** updated to v2.13.0

---

## [2.12.0] - 2026-03-24

### Changed
- **ARCKnowledge submodule** updated to v2.12.0

---

## [2.11.0] - 2026-03-21

### Changed
- **ARCKnowledge submodule** updated to v2.11.0

---

## [2.10.0] - 2026-03-20

### Changed
- **ARCKnowledge submodule** updated to v2.10.0

---

## [2.9.0] - 2026-03-14

### Added
- **Agent symlink installation** — `arcdevtools-setup` now symlinks ARCKnowledge agents into `.claude/agents/` following the same pattern as skills. Projects gain 4 new autonomous agents automatically on re-setup:
  - `arc-testflight` — beta build distribution to TestFlight
  - `arc-aso` — App Store Optimization orchestration
  - `arc-swiftdata-migration` — high-risk schema migration with test-first enforcement
  - `arc-dependency-auditor` — read-only SPM ecosystem audit

### Changed
- **ARCKnowledge submodule** updated to v2.9.0
- **arcdevtools-setup version** bumped to 1.1.0

---

## [2.8.0] - 2026-03-12

### Added

- **Xcode Cloud templates** — 3 `ci_scripts/` templates in `templates/ci_scripts/`:
  - `ci_post_clone.sh` — installs dependencies and ARCDevTools after clone
  - `ci_pre_xcodebuild.sh` — runs SwiftLint and SwiftFormat validation before build
  - `ci_post_xcodebuild.sh` — post-build cleanup and artifact handling
- **Xcode Cloud setup guide** — new `docs/xcode-cloud-setup.md` with complete step-by-step integration instructions
- **ARCKnowledge submodule updated** to v2.8.0

### Changed

- **`arcdevtools-setup` script** — added Xcode Cloud detection and `ci_scripts/` installation for iOS App projects
- **`docs/ci-cd.md`** — extended with Xcode Cloud section alongside GitHub Actions docs
- **`README.md`** — updated to document Xcode Cloud support and new `ci_scripts/` templates
- **`CLAUDE.md`** — updated agent instructions to reflect Xcode Cloud additions

### Fixed

- **SwiftFormat config** — changed `--type-attributes` back to `prev-line` so `@MainActor`, `@Observable`, and other type-level attributes appear on their own line before `class`/`struct`/`actor` declarations

---

## [2.7.6] - 2026-03-04

### Fixed

- **SwiftFormat config** — Changed `--type-attributes` from `same-line` to `prev-line` so `@MainActor`, `@Observable`, and other type-level attributes appear on their own lines before `class`/`struct`/`actor` declarations. This matches the ARC Labs style for `@Observable` ViewModels.
- **SwiftLint config** — Fixed `observable_viewmodel` custom rule regex: replaced the lookahead `(?!.*@Observable)` (which could never match with `prev-line` attributes) with a negative lookbehind `(?<!@Observable\n)` that correctly detects when `@Observable` does not immediately precede `final class`. Eliminates false positives on all ViewModels.

---

## [2.7.5] - 2026-03-01

### Fixed

- **SwiftLint config** — Removed `multiline_arguments` and `multiline_parameters` opt-in rules that conflicted with SwiftFormat's `--wraparguments after-first` and `--wrapparameters after-first` settings. SwiftFormat aligns continuation args after the first arg on the same line, while SwiftLint required all-or-nothing multiline formatting — unresolvable without changing the wrap style. Removed associated rule-specific configuration blocks.

---

## [2.7.4] - 2026-03-01

### Fixed

- **SwiftFormat config** — Disabled `wrapMultilineStatementBraces` rule that placed `{` on a new line after multiline parameter lists, conflicting with SwiftLint's `opening_brace` rule (K&R style required)
- **SwiftLint config** — Removed `multiline_literal_brackets` opt-in rule that conflicted with SwiftFormat's `--wrapcollections after-first` setting
- **Pre-commit hook** — Staged files are now filtered to only paths listed under `included:` in `.swiftlint.yml` (Sources/Tests) before linting, so files in `Examples/` and `Package.swift` are never passed to SwiftLint

---

## [2.7.3] - 2026-02-28

### Fixed

- **SwiftFormat config** — Changed `--closingparen` from `balanced` to `same-line` to resolve conflicts with SwiftLint's multiline rules
- **SwiftLint config** — Removed `multiline_arguments_brackets` and `multiline_parameters_brackets` rules that conflicted with SwiftFormat
- **SwiftLint config** — Added `excluded_match_kinds` (comment, doccomment, string) to `observable_viewmodel` custom rule to prevent false positives

---


## [2.7.2] - 2026-02-24

### Fixed

- **Pre-push hook** — Support Xcode projects and Makefile detection; was previously hardcoded to `swift test --parallel` only
- **Hook installer** — `install-hooks.sh` now installs the pre-push hook (was only installing pre-commit)

---

## [2.7.1] - 2026-02-24

### Fixed

- **Setup script** — Configure `pull.rebase=true` and remove `merge.ff=false` to prevent unwanted merge commits on pull after PR merges

---


## [2.7.0] - 2026-02-20

### Added

- **Claude Code hooks** — 4 hooks for real-time quality feedback during AI-assisted development:
  - `format-on-save.sh` (PostToolUse) — Auto-formats `.swift` files with SwiftFormat after Edit/Write
  - `validate-commit.sh` (PreToolUse) — Validates Conventional Commits format before `git commit`
  - `session-start.sh` (SessionStart) — Shows branch, last release, and pending changes on session start
  - `block-dangerous-git.sh` (PreToolUse) — Blocks force-push to main/develop, destructive resets, and clean operations
- **Project hook configuration** — `.claude/settings.json` with PostToolUse, PreToolUse, Stop prompt, and SessionStart hooks
- **Stop prompt hook** — Reminds Claude to verify `swift build` passes when `.swift` files were edited

### Fixed

- **block-dangerous-git** — Allow `git reset --hard origin/*` (safe sync to remote tracking branch)
- **Hook false positives** — Strip heredoc content and quoted strings before pattern matching; anchor validate-commit to command start

### Removed

- **notification.sh** — Removed in favor of Ghostty terminal notifications (avoids duplicates)

---

## [2.6.0] - 2026-02-19

### Added

- **CLAUDE.md** — Agent instructions for working on the ARCDevTools repository
- **SwiftLint multiline rules** — `multiline_arguments` and `multiline_parameters` with `first_argument_location: same_line`
- **Security patterns** in `.gitignore` (sensitive files, credentials, provisioning profiles)

### Changed

- **ARCKnowledge submodule updated** to v2.6.0 (11 skills)
- **README.md** rewritten as implementation guide with complete skills documentation
- **SwiftFormat** — All attributes set to same-line (`--type-attributes`, `--func-attributes`, `--stored-var-attributes`, `--computed-var-attributes`, `--complex-attributes`)
- **SwiftLint** — `multiline_arguments_brackets` and `multiline_parameters_brackets` rules enabled

---

## [2.5.0] - 2026-02-06

### Changed

- **ARCKnowledge submodule updated** to v2.5.0

---

## [2.4.1] - 2026-02-05

### Changed

- **ARCKnowledge submodule updated** to v2.4.0

---

## [2.4.0] - 2026-02-03

### Added

- **Branch protection configuration script** (`scripts/setup-branch-protection-all.sh`)
  - Configures branch protection rules for all ARC Labs repositories
  - Ensures consistent protection across main and develop branches

### Changed

- **ARCKnowledge submodule updated** to latest version

---

## [2.3.0] - 2025-01-XX

### Added

- Claude Code GitHub Actions automation scripts
- CI workflow improvements for Claude Code integration

### Fixed

- Claude workflow permissions (contents: write)

---

## [2.2.0] - 2025-01-XX

### Fixed

- FileManager.createSymbolicLink API usage in setup script

### Added

- Auto-install ARCKnowledge skills during setup

---

## [2.1.0] - 2025-01-XX

### Changed

- ARCKnowledge submodule updated to v2.0.1

---

## [2.0.0] - 2025-01-XX

### Added

- Claude Code skills support in ARCDevTools
- `arc-package-validator` skill: validates Swift Packages against ARCKnowledge standards
  - Structure validation (Package.swift, README, LICENSE, etc.)
  - Configuration validation (ARCDevTools integration, SwiftLint, SwiftFormat)
  - Documentation validation (badges, required sections)
  - Code quality validation (SwiftLint execution, SwiftFormat check, build)
  - Auto-fix mode with `--fix` flag
- `arcdevtools-setup` now installs Claude Code skills automatically

### Changed

- **ARCKnowledge submodule updated to v2.0.0** - Major architecture change
  - Migrated from flat document loading to **Claude Code Skills** system
  - Reduces token usage by ~87% through progressive context loading
  - `CLAUDE.md` minified from ~850 lines to ~200 lines (core philosophy only)
  - 7 new skills available via slash commands:
    - `/arc-swift-architecture` - Clean Architecture, MVVM+C, SOLID, Protocol-Oriented
    - `/arc-tdd-patterns` - Swift Testing, TDD workflow, coverage requirements
    - `/arc-quality-standards` - Code review, SwiftLint/Format, documentation, accessibility
    - `/arc-data-layer` - Repositories, API clients, DTOs, caching strategies
    - `/arc-presentation-layer` - Views, ViewModels, @Observable, navigation
    - `/arc-workflow` - Conventional Commits, branches, PRs, Plan Mode
    - `/arc-project-setup` - Packages, apps, ARCDevTools integration, Xcode, CI/CD
  - Skills load detailed documentation on-demand instead of all at once

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

[Unreleased]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.8.0...HEAD
[2.8.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.6...v2.8.0
[2.7.6]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.5...v2.7.6
[2.7.5]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.4...v2.7.5
[2.7.4]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.3...v2.7.4
[2.7.3]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.2...v2.7.3
[2.7.2]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.1...v2.7.2
[2.7.1]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.7.0...v2.7.1
[2.7.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.4.1...v2.5.0
[2.4.1]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/arclabs-studio/ARCDevTools/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/arclabs-studio/ARCDevTools/releases/tag/v1.0.0
