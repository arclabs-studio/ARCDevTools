# CI/CD Guide

This guide covers GitHub Actions configuration for ARC Labs projects, with special attention to **billing optimization** for private repositories.

---

## Table of Contents

- [Billing Overview](#billing-overview)
- [Runner Multipliers](#runner-multipliers)
- [Workflow Optimization Strategy](#workflow-optimization-strategy)
- [iOS Simulator Runtime](#ios-simulator-runtime)
- [Alternatives to GitHub Actions](#alternatives-to-github-actions)
- [Configuration Reference](#configuration-reference)

---

## Billing Overview

GitHub Actions has **different billing tiers** based on repository visibility:

| Repository Type | Free Minutes | Storage |
|----------------|--------------|---------|
| **Public** | Unlimited | 500 MB |
| **Private (Free plan)** | 2,000 min/month | 500 MB |
| **Private (Team)** | 3,000 min/month | 2 GB |
| **Private (Enterprise)** | 50,000 min/month | 50 GB |

> **Important:** These minutes are **Linux minutes**. Other runners have multipliers.

---

## Runner Multipliers

Different runners consume minutes at different rates:

| Runner | Multiplier | Effective Free Minutes (Private) |
|--------|------------|----------------------------------|
| `ubuntu-latest` | 1x | 2,000 minutes |
| `windows-latest` | 2x | 1,000 minutes |
| `macos-latest` | 10x | **200 minutes** |
| `macos-15` | 10x | **200 minutes** |

### Impact on iOS Development

For iOS projects, this means:

- A typical iOS build: **8-12 minutes**
- With 10x multiplier: **80-120 minutes consumed**
- Maximum builds per month: **~15-20 builds**

This severely limits CI/CD capacity for private iOS repositories on the free tier.

---

## Workflow Optimization Strategy

ARCDevTools workflows are optimized to minimize macOS usage:

### 1. Quality Checks on Ubuntu

SwiftLint and SwiftFormat run on `ubuntu-latest` (1x multiplier):

```yaml
# workflows-ios/quality.yml
jobs:
  swiftlint:
    runs-on: ubuntu-latest  # 1x multiplier
    steps:
      - uses: norio-nomura/action-swiftlint@3.2.1
        with:
          args: --strict
```

**Savings:** ~5 minutes Linux vs 50 minutes macOS equivalent per PR.

### 2. Combined Build & Test Job

Instead of separate jobs, build and test run sequentially on the same runner:

```yaml
# workflows-ios/tests.yml
jobs:
  build-and-test:  # Single job instead of detect + build + test
    runs-on: macos-15
    steps:
      - name: Detect scheme
      - name: Build for iOS
      - name: Run tests
```

**Savings:** ~4 minutes (eliminates job startup overhead).

### 3. Markdown Validation on Ubuntu

Link checking runs on Linux:

```yaml
markdown-links:
  runs-on: ubuntu-latest
  steps:
    - uses: gaurav-nelson/github-action-markdown-link-check@v1
```

---

## iOS Simulator Runtime

### The Problem

GitHub's `macos-15` runners **do not have iOS Simulator runtime preinstalled**. Only visionOS is available by default.

Without proper handling, builds fail with:
```
xcodebuild: error: Unable to find a destination matching the provided destination specifier
```

### The Solution

ARCDevTools workflows automatically:

1. **Check if iOS runtime is available:**
```bash
xcrun simctl list runtimes | grep -qE "iOS.*--"
```

2. **Download if missing:**
```bash
xcodebuild -downloadPlatform iOS
```

3. **Wait for simulators to register:**
```bash
sleep 30  # Simulators need time to appear
```

4. **Find available simulator dynamically:**
```bash
for DEVICE in "iPhone 16 Pro" "iPhone 16" "iPhone 15 Pro" "iPhone 15"; do
  if xcrun simctl list devices available | grep -q "$DEVICE"; then
    SIMULATOR="$DEVICE"
    break
  fi
done
```

### First-Run Impact

The first workflow run may take **5-10 extra minutes** to download the iOS runtime. Subsequent runs use cached runtimes.

---

## Alternatives to GitHub Actions

For high-volume iOS CI/CD, consider these alternatives:

### 1. Xcode Cloud (Recommended for Apple Developers)

| Feature | Details |
|---------|---------|
| **Free Tier** | 25 compute hours/month |
| **Requirements** | Apple Developer Program membership |
| **Advantages** | Native Xcode integration, no simulator issues |
| **Best For** | Production iOS apps |

**Setup:**
1. Open your project in Xcode
2. Product > Xcode Cloud > Create Workflow
3. Follow the setup wizard

### 2. Codemagic

| Feature | Details |
|---------|---------|
| **Free Tier** | 500 build minutes/month |
| **Pricing** | $0.038/min (macOS M2) |
| **Advantages** | Mobile-focused, code signing built-in |
| **Best For** | Teams needing more minutes |

### 3. Self-Hosted Runners

| Feature | Details |
|---------|---------|
| **Cost** | No billing multiplier |
| **Requirements** | Mac hardware, maintenance |
| **Advantages** | Unlimited minutes, full control |
| **Best For** | Large teams, enterprise |

**Setup:**
```bash
# On your Mac:
# 1. Go to repo Settings > Actions > Runners > New self-hosted runner
# 2. Follow the download and configure instructions
# 3. Run: ./run.sh

# In workflow:
jobs:
  build:
    runs-on: self-hosted
```

### 4. Bitrise

| Feature | Details |
|---------|---------|
| **Free Tier** | Limited builds |
| **Advantages** | Mobile-specialized, many integrations |
| **Best For** | Mobile-first teams |

### Comparison Table

| Solution | Free Tier | macOS Cost | Simulator Issues |
|----------|-----------|------------|------------------|
| GitHub Actions | 200 min (effective) | 10x multiplier | Yes |
| Xcode Cloud | 25 hours | None | No |
| Codemagic | 500 min | ~$0.04/min | No |
| Self-hosted | Unlimited | Hardware cost | No |

---

## Configuration Reference

### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable | Description | Example |
|----------|-------------|---------|
| `XCODE_SCHEME` | Override auto-detected scheme | `MyApp` |
| `XCODE_DESTINATION` | Override simulator selection | `platform=iOS Simulator,name=iPhone 15,OS=17.0` |

### Workflow Files

| File | Runner | Purpose |
|------|--------|---------|
| `quality.yml` | ubuntu-latest | SwiftLint, SwiftFormat, Markdown |
| `tests.yml` | macos-15 | Xcode build and tests |
| `enforce-gitflow.yml` | ubuntu-latest | Branch rules validation |
| `sync-develop.yml` | ubuntu-latest | Auto-sync main to develop |

### Estimated Monthly Usage (Private Repo)

For a typical project with ~30 PRs/month:

| Workflow | Runs | Minutes Each | Total (Effective) |
|----------|------|--------------|-------------------|
| Quality (Ubuntu) | 60 | 3 min | 180 min |
| Tests (macOS) | 30 | 12 min | **3,600 min** |
| Git Flow (Ubuntu) | 30 | 1 min | 30 min |

**Total:** ~3,810 effective minutes (exceeds 2,000 free tier)

**Solution:** Use Xcode Cloud for tests, GitHub Actions for quality checks.

---

## Best Practices

1. **Run quality checks on Ubuntu** - SwiftLint and SwiftFormat work on Linux
2. **Minimize macOS jobs** - Only use for actual Xcode operations
3. **Combine related steps** - Reduce job startup overhead
4. **Cache dependencies** - SPM packages, CocoaPods, derived data
5. **Skip unnecessary builds** - Use path filters to skip when only docs change
6. **Consider Xcode Cloud** - Free 25 hours covers most small projects

---

## Troubleshooting

### "No matching destination" Error

**Cause:** iOS simulator runtime not installed.

**Solution:** ARCDevTools workflows handle this automatically. If using custom workflows, add:

```yaml
- name: Ensure iOS Runtime
  run: |
    if ! xcrun simctl list runtimes | grep -qE "iOS.*--"; then
      xcodebuild -downloadPlatform iOS
      sleep 30
    fi
```

### Build Takes Too Long

**Cause:** iOS runtime download on first run.

**Solution:** First run will be slower (~5-10 min extra). Subsequent runs use cached runtime.

### "Billing limit exceeded" Error

**Cause:** Free tier exhausted.

**Solutions:**
1. Wait for monthly reset
2. Upgrade GitHub plan
3. Switch to Xcode Cloud for iOS builds
4. Set up self-hosted runner

---

## Additional Resources

- [GitHub Actions Billing Documentation](https://docs.github.com/en/billing/managing-billing-for-github-actions)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Self-hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
