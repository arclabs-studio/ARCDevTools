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

### `format.sh`

Runs SwiftFormat to check code formatting.

**Usage:**
```bash
./scripts/format.sh
```

---

### `lint.sh`

Runs SwiftLint to check code style and quality.

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
