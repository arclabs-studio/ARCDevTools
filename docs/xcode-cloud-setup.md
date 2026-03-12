# Xcode Cloud Setup Guide

Xcode Cloud is Apple's native CI/CD service, tightly integrated with Xcode and App Store Connect. It is the **recommended CI/CD solution for ARC Labs iOS apps** due to its native simulator support, free 25-hour monthly tier, and zero configuration overhead for Apple platform specifics.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Getting Started in Xcode](#getting-started-in-xcode)
- [Private SPM Dependencies](#private-spm-dependencies)
- [Recommended Workflows](#recommended-workflows)
- [ci_scripts Reference](#ci_scripts-reference)
- [Environment Variables](#environment-variables)
- [Hour Budget Strategy](#hour-budget-strategy)
- [Troubleshooting](#troubleshooting)

---

## Overview

| Feature | Details |
|---------|---------|
| **Free Tier** | 25 compute hours/month |
| **Requirements** | Apple Developer Program membership |
| **Advantages** | Native Xcode integration, no simulator issues, automatic code signing |
| **Configuration** | Via Xcode/App Store Connect UI — no YAML files |
| **Customization** | `ci_scripts/` shell scripts auto-detected by Xcode Cloud |

Unlike GitHub Actions, Xcode Cloud has no YAML workflow files. Workflows are configured in the Xcode UI or App Store Connect. Repository customization happens exclusively through `ci_scripts/` shell scripts.

---

## Prerequisites

Before setting up Xcode Cloud, verify:

1. **`Package.resolved` is tracked in git** — Required for deterministic SPM dependency resolution.
   - Path: `<AppName>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
   - Confirm it is NOT in `.gitignore`

2. **Apple Developer Program membership** — Required for Xcode Cloud access.

3. **App Store Connect app record exists** — Xcode Cloud links to an App Store Connect app. Create one at [appstoreconnect.apple.com](https://appstoreconnect.apple.com) if needed.

4. **Private SPM dependencies authorized** — If your project uses private GitHub packages, grant Xcode Cloud access (see [Private SPM Dependencies](#private-spm-dependencies)).

---

## Getting Started in Xcode

1. Open your project in Xcode
2. Navigate to **Report Navigator** (⌘9) → **Cloud** tab
3. Click **Get Started** and follow the authorization flow
4. Grant Xcode Cloud access to your SCM provider (GitHub)
5. Xcode Cloud auto-detects your app and creates a default workflow

On first setup, Xcode Cloud runs a "bootstrap" build to validate the configuration.

---

## Private SPM Dependencies

Xcode Cloud clones your repository using your SCM provider token. For **private SPM dependencies** hosted on GitHub:

1. Open **App Store Connect** → **Xcode Cloud** → your app
2. Navigate to **Settings** → **Additional Repositories**
3. Click **+** and grant access to each private repository
4. Xcode Cloud will use your connected GitHub account to clone them

> **Note**: Submodules (like `Tools/ARCDevTools`) are also fetched using the SCM provider credentials. Ensure Xcode Cloud has access to all private submodule repositories.

---

## Recommended Workflows

Set up these three workflows in Xcode/App Store Connect:

| Workflow | Trigger | Actions | Est. Time |
|----------|---------|---------|-----------|
| **CI** | Push to `main` or `develop` | Build + Test | ~8 min |
| **PR Validation** | PR opened/updated | Build + Test | ~8 min |
| **Release** | Tag matching `v*.*.*` | Archive → TestFlight | ~12 min |

### CI Workflow

**Purpose**: Validate every push to main branches.

- **Start Condition**: Push to `main` or `develop`
- **Actions**:
  1. Build — scheme: `<AppName>-iOS`, platform: iOS Simulator
  2. Test — same scheme, run all tests
- **Notify**: On failure only

### PR Validation Workflow

**Purpose**: Validate every pull request before merge.

- **Start Condition**: Pull request opened or updated
- **Actions**:
  1. Build — scheme: `<AppName>-iOS`, platform: iOS Simulator
  2. Test — same scheme
- **SwiftLint**: Runs automatically via `ci_post_clone.sh`
- **Notify**: On failure, notify PR author

### Release Workflow

**Purpose**: Archive and distribute to TestFlight on version tags.

- **Start Condition**: Tag matching `v*.*.*` (e.g., `v1.2.0`)
- **Actions**:
  1. Archive — scheme: `<AppName>-iOS`, distribution: TestFlight
- **Post-Action**: Auto-submit to TestFlight (optional)
- **Notify**: Always (success and failure)

---

## ci_scripts Reference

Xcode Cloud auto-detects scripts in the `ci_scripts/` directory at the **project root** (same level as `.gitignore`). Scripts must be **executable** (`chmod +x`).

Copy templates from `templates/ci_scripts/` into your project root:

```bash
mkdir -p ci_scripts
cp Tools/ARCDevTools/templates/ci_scripts/*.sh ci_scripts/
chmod +x ci_scripts/*.sh
```

| Script | When It Runs | Purpose |
|--------|-------------|---------|
| `ci_post_clone.sh` | After repo clone, before any build | Verify Package.resolved, install SwiftLint |
| `ci_pre_xcodebuild.sh` | Before each xcodebuild action | Log build context (action, platform, PR/tag info) |
| `ci_post_xcodebuild.sh` | After each xcodebuild action | Log results (archive path, test results path) |

---

## Environment Variables

Xcode Cloud injects these environment variables into `ci_scripts/`:

| Variable | When Set | Description |
|----------|----------|-------------|
| `CI_BRANCH` | Always | Current branch name |
| `CI_WORKFLOW` | Always | Workflow name |
| `CI_BUILD_NUMBER` | Always | Build number |
| `CI_COMMIT` | Always | Git commit hash |
| `CI_XCODEBUILD_ACTION` | pre/post_xcodebuild | `build`, `test`, or `archive` |
| `CI_PRODUCT_PLATFORM` | pre/post_xcodebuild | `iOS`, `macOS`, `tvOS`, etc. |
| `CI_PULL_REQUEST_NUMBER` | PR builds only | Pull request number |
| `CI_TAG` | Tag builds only | Git tag name |
| `CI_ARCHIVE_PATH` | post_xcodebuild (archive) | Path to `.xcarchive` |
| `CI_TEST_RESULTS_PATH` | post_xcodebuild (test) | Path to `.xcresult` bundle |

> **Full reference**: [Xcode Cloud environment variable reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)

---

## Hour Budget Strategy

The free tier provides **25 compute hours/month**. With the recommended three workflows:

| Workflow | Runs/Month | Time Each | Monthly Cost |
|----------|-----------|-----------|-------------|
| CI (push to main/develop) | ~20 | ~8 min | ~2.7 hrs |
| PR Validation | ~30 | ~8 min | ~4.0 hrs |
| Release (tags) | ~4 | ~12 min | ~0.8 hrs |
| **Total** | | | **~7.5 hrs** |

At typical activity, the free tier is more than sufficient. Tips to stay within budget:

- **Limit CI to main branches** — Don't trigger on every feature branch push
- **Use concurrency limits** — Set max 1 concurrent build per workflow to avoid burst usage
- **Skip builds for doc-only changes** — Use start condition filters on file paths
- **Archive only on tags** — Never archive on every commit

---

## Troubleshooting

### SPM resolution fails / "No such module"

**Cause**: `Package.resolved` not tracked in git, or Xcode Cloud lacks access to a private dependency.

**Fix**:
1. Confirm `Package.resolved` is committed (not in `.gitignore`)
2. In App Store Connect → Xcode Cloud → Settings → Additional Repositories, add all private SPM repos
3. Re-run the failed build

### `ci_post_clone.sh` not running

**Cause**: Script not executable or not at project root level.

**Fix**:
```bash
ls -la ci_scripts/  # Confirm executable bit (x)
chmod +x ci_scripts/*.sh
git add ci_scripts/ && git commit -m "fix(ci): make ci_scripts executable"
```

### Code signing fails on archive

**Cause**: Xcode Cloud needs a distribution certificate and provisioning profile.

**Fix**:
1. In Xcode Cloud workflow settings → Archive action → enable **Automatic Signing**
2. Ensure your Apple Developer account has a valid distribution certificate
3. Xcode Cloud manages provisioning profiles automatically when using Automatic Signing

### Build time out (> 30 min)

**Cause**: First build downloads iOS simulator runtime (~5-10 min extra). SPM dependency resolution can also add time.

**Fix**: The first build is always slower. Subsequent builds use cached runtimes and resolved packages.

### Workflow not triggering on PR

**Cause**: GitHub webhook not connected, or branch filter too restrictive.

**Fix**:
1. In App Store Connect → Xcode Cloud → your workflow → Edit
2. Verify the Start Condition matches your PR target branch
3. Check that the SCM provider integration is active in Xcode Cloud settings

---

## Additional Resources

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Environment Variable Reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)
- [ci_scripts Documentation](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- [App Store Connect](https://appstoreconnect.apple.com)
