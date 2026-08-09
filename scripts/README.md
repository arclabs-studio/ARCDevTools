# ARCDevTools Scripts

Automation scripts for ARC Labs Studio development workflow.

## GitHub Configuration Scripts

### `setup-branch-protection-all-repos.sh`

Configures branch protection rules across **all public repositories** in the arclabs-studio organization.

**What it does:**
- Configures `main` branch protection:
  - ❌ No deletion allowed
  - ❌ No force push allowed
  - ✅ Rules enforced for admins
  - ✅ No approval requirement (optimized for solo development)
- Configures `develop` branch protection:
  - ❌ No deletion allowed
  - ❌ No force push allowed
  - ✅ Admins can bypass rules (allows synchronization)

**Usage:**
```bash
./scripts/setup-branch-protection-all-repos.sh
```

**Requirements:**
- GitHub CLI (`gh`) installed and authenticated
- Admin access to arclabs-studio organization
- GitHub Pro required for private repositories

**Logs:**
- Creates timestamped log files in `logs/branch-protection-YYYYMMDD-HHMMSS.log`

---

### `setup-branch-protection.sh`

Configures branch protection for the ARCDevTools repository only.

**Usage:**
```bash
./scripts/setup-branch-protection.sh
```

---

### `setup-github-labels.sh`

Configures standard GitHub labels for ARCDevTools repository.

**Usage:**
```bash
./scripts/setup-github-labels.sh
```

---

## Development Scripts

### `install-tools.sh`

Installs the exact SwiftLint and SwiftFormat versions pinned in
[`configs/tool-versions`](../configs/tool-versions) (or the consumer project's
`.arc-tool-versions`) into `<repo>/.arc-tools/bin`.

Downloads the official release binaries directly — **never** Homebrew, which
has no versioned formula and silently drifts to latest. That drift is what made
`--strict` CI fail on PRs that were green locally.

Supports macOS (universal binary) and Linux x86_64/arm64 (uses the statically
linked SwiftLint build, so bare CI images need no Swift toolchain). Idempotent:
a tool already at the pinned version is left alone.

**Usage:**
```bash
./scripts/install-tools.sh              # both tools
./scripts/install-tools.sh swiftlint    # one tool
./scripts/install-tools.sh --force      # reinstall
```

In consumer projects: `make tools`.

---

### `tool-env.sh`

**Sourced, not executed.** Resolves the pinned SwiftLint/SwiftFormat binaries
for git hooks, `lint.sh`, `format.sh` and `pr-ready.sh`.

Resolution order: `.arc-tools/bin/<tool>` at the pinned version → `<tool>` on
PATH at the pinned version → `<tool>` on PATH at any version (reported as
drift) → missing.

**Exports:** `SWIFTLINT_BIN`, `SWIFTFORMAT_BIN`, `SWIFTLINT_VERSION`,
`SWIFTFORMAT_VERSION`, `SWIFTLINT_STATUS`, `SWIFTFORMAT_STATUS`, plus the
`arc_tool_warn <tool>` helper that prints a drift/missing warning with the fix.

**Usage:**
```bash
source ARCDevTools/scripts/tool-env.sh
arc_tool_warn swiftlint
"$SWIFTLINT_BIN" lint --strict
```

---

### `format.sh`

Runs the pinned SwiftFormat to check code formatting.

**Usage:**
```bash
./scripts/format.sh
```

---

### `lint.sh`

Runs the pinned SwiftLint to check code style and quality.

**Usage:**
```bash
./scripts/lint.sh
```

---

### `pr-ready.sh`

Validates that your branch is ready for a pull request by running:
- SwiftLint
- SwiftFormat
- Other pre-PR checks

**Usage:**
```bash
./scripts/pr-ready.sh
```

---

### `setup-skills.sh`

Installs Claude Code skills for ARCDevTools workflows.

**Usage:**
```bash
./scripts/setup-skills.sh
```

---

### `arc-setup-notes-system.sh`

Bootstraps the ARC notes/Obsidian system in any ARC repo. Creates
`.claude/hooks/setup-notes.sh` (creates the `notes/` symlink to the project's
Obsidian vault folder) and `.claude/hooks/sync-plans.sh` (Stop hook that
archives Claude plans). Appends `notes` to `.gitignore`. Idempotent.

**What it does:**
- Detects project name from `git rev-parse --show-toplevel` (strips
  `-iOS` / `-Android` / `-Web` / `-macOS` suffix)
- Writes both hook scripts (skips if already up-to-date)
- Adds `notes` to `.gitignore` if missing
- Runs `setup-notes.sh` to create the symlink when the vault folder exists
- Prints next steps for wiring the hooks into `.claude/settings.local.json`

**Cross-machine safe:** generated hooks resolve `$HOME` at runtime; never
hardcode the current user. Re-run after every clone or worktree creation.

**Usage:**
```bash
./scripts/arc-setup-notes-system.sh                       # auto-detect
./scripts/arc-setup-notes-system.sh --name FavRes         # explicit name
./scripts/arc-setup-notes-system.sh --root ~/path --dry-run
./scripts/arc-setup-notes-system.sh --verbose
```

---

### `arc-memory-prune.sh`

Audits Claude Code's auto-memory directories
(`~/.claude/projects/*/memory/`) and reports stale entries (default: not
modified in more than 60 days). Read-only by default.

**What it does:**
- Walks every project under `$HOME/.claude/projects/`
- Color-codes each file by age (green < 30d, yellow 30-60d, red >= 60d)
- Parses `name:` and `description:` from frontmatter when present
- Reports per-project totals (file count, stale count, oldest, total size)
- With `--delete`, prompts per-file before removing (skip prompts with `--yes`)

**Cross-machine safe:** scans only the current user's `~/.claude` tree.

**Usage:**
```bash
./scripts/arc-memory-prune.sh                  # report only
./scripts/arc-memory-prune.sh --days 90        # custom threshold
./scripts/arc-memory-prune.sh --verbose        # show all files, not just stale
./scripts/arc-memory-prune.sh --delete         # interactive prune
./scripts/arc-memory-prune.sh --delete --yes   # non-interactive prune
```

---

### `check-localization.py`

Checks String Catalog (`*.xcstrings`) completeness for required locales. Fails (exit 1) when any key is missing a translation or is in `new` / `needs_review` state.

Auto-discovers all `.xcstrings` files from the working directory (skipping `.build`, `Build`, `DerivedData`, `Pods`, `Carthage`, `node_modules`, `.swiftpm`, `.git`). Pass `--catalog` to scope to a single file.

**When to use:**

- **iOS apps with String Catalogs** — add `lint-l10n` to your Makefile (see below). Wire it into `lint:` so CI catches missing translations.
- **SPM packages** — skip this script. ARC packages are text-agnostic: they use `LocalizedStringKey` literals with English defaults; the consuming app's String Catalog resolves translations. Running the script in a package project is safe (exits 0 silently when no catalogs are found), but there is nothing to check.
- **Unsure?** — run bare with no flags. If no `.xcstrings` files exist, the script exits 0 and does nothing.

**Usage:**

```bash
# Auto-discover all catalogs, require Spanish (default)
python3 ARCDevTools/scripts/check-localization.py

# Single catalog, multiple required locales
python3 ARCDevTools/scripts/check-localization.py \
    --catalog Sources/Resources/Localizable.xcstrings \
    --locales es,fr,de

# List all catalogs (even on success)
python3 ARCDevTools/scripts/check-localization.py --verbose
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--locales` | `es` | Comma-separated required locales |
| `--catalog` | (auto-discover) | Path to a single `.xcstrings` file |
| `--verbose` | off | Show all checked catalogs even on success |

**Wire into Makefile:**

```makefile
lint-l10n:
	@python3 ARCDevTools/scripts/check-localization.py \
		--catalog Path/To/Localizable.xcstrings \
		--locales es

lint: lint-l10n
	# ... existing lint steps
```

**Requirements:** Python 3.9+ (uses `Path.is_relative_to`, type hints, `from __future__ import annotations`).

---

### `key-obfuscator.swift`

Generates a lightly-obfuscated `[UInt8]` literal for a **client-public** key
(e.g. a RevenueCat or Firebase SDK key) so it does not appear as a plain `String`
in the binary. Reconstruct at runtime with `ARCStorage.ConfigurationValue.deobfuscated(_:)`.

> ⚠️ Light obfuscation only — a speed-bump against casual scraping, **not** a
> secret store. Never use it for real secrets; see `ARCKnowledge/Quality/api-keys.md`.

**Usage:**
```bash
swift scripts/key-obfuscator.swift "appl_yourKey" --name rcAPIKey
```

---

## GitHub Actions Scripts

See `scripts/github-actions/README.md` for automation scripts related to GitHub Actions workflows.

---

## Notes

- All scripts are designed to be run from the repository root
- Scripts use color-coded output for better readability
- Most scripts require `gh` CLI to be installed and authenticated
- Log files are stored in the `logs/` directory (gitignored)

---

## Contributing

When adding new scripts:
1. Make them executable: `chmod +x scripts/your-script.sh`
2. Add usage documentation to this README
3. Use consistent error handling and color-coded output
4. Add shebang: `#!/bin/bash`
5. Use `set -e` for better error handling
