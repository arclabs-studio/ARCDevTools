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
