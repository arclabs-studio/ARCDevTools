# CI/CD with GitHub Actions

Complete guide to understanding and configuring continuous integration and deployment for ARCDevTools.

## Overview

This guide explains how to set up and use GitHub Actions workflows for automated quality checks, testing, and documentation generation. If you're new to CI/CD, this guide will walk you through everything you need to know.

## What is CI/CD?

**CI/CD** stands for **Continuous Integration** and **Continuous Deployment**:

- **Continuous Integration (CI)**: Automatically building and testing code every time changes are pushed
- **Continuous Deployment (CD)**: Automatically deploying code to production when tests pass

### Why Use CI/CD?

**Benefits:**
- ✅ **Catch bugs early** - Tests run on every commit
- ✅ **Consistent quality** - Same checks for everyone
- ✅ **No manual work** - Automation saves time
- ✅ **Confidence in changes** - Know immediately if something breaks
- ✅ **Better collaboration** - Everyone sees test results

**Example workflow:**
1. You push code to GitHub
2. GitHub Actions automatically runs tests
3. If tests fail, you're notified immediately
4. If tests pass, code can be merged

## GitHub Actions Basics

### What are GitHub Actions?

GitHub Actions is a CI/CD platform built into GitHub. It runs your workflows automatically when certain events happen (like pushing code or creating a pull request).

### Key Concepts

**Workflow**: A YAML file that defines what to run and when
```yaml
name: Tests
on: push          # When to run
jobs:             # What to run
  test:
    runs-on: macos-latest
    steps:
      - run: swift test
```

**Event**: What triggers a workflow (push, pull_request, schedule, etc.)

**Job**: A set of steps that run on the same machine

**Step**: Individual task (checkout code, run command, etc.)

**Runner**: The machine that executes your workflow (macos-latest, ubuntu-latest, etc.)

## ARCDevTools Workflows

ARCDevTools includes three workflows:

### 1. Code Quality (`quality.yml`)

**Purpose**: Ensure code follows style guidelines

**When it runs:**
- Every push to `main`, `develop`, or `feature/*` branches
- Every pull request to `main` or `develop`

**What it does:**
1. **SwiftLint Job**
   - Installs SwiftLint
   - Runs linting with strict mode (warnings treated as errors)
   - Fails if any violations found

2. **SwiftFormat Job**
   - Installs SwiftFormat
   - Checks if code is properly formatted
   - Fails if formatting changes needed

**Reading the results:**
```
✅ SwiftLint - Passed (no violations)
❌ SwiftFormat - Failed (code needs formatting)
```

### 2. Tests (`tests.yml`)

**Purpose**: Verify code works correctly

**When it runs:**
- Every push to `main`, `develop`, or `feature/*` branches
- Every pull request to `main` or `develop`

**What it does:**
1. **macOS Job**
   - Uses Xcode 16.0
   - Runs all tests in parallel
   - Swift 6.0 on macOS

2. **Linux Job**
   - Uses Swift 6.0 Docker container
   - Runs all tests in parallel
   - Ensures cross-platform compatibility

**Reading the results:**
```
✅ Test on macOS - Passed (10/10 tests)
✅ Test on Linux - Passed (10/10 tests)
```

### 3. Documentation (`docs.yml`)

**Purpose**: Generate DocC documentation

**When it runs:**
- Every push to `main` branch
- Manually via workflow_dispatch

**What it does:**
1. Builds DocC documentation
2. Uploads as artifact (downloadable for 30 days)
3. (Optional) Can deploy to GitHub Pages

**Reading the results:**
```
✅ Build DocC Documentation - Passed
📦 Artifact available: documentation
```

## Setting Up CI/CD

### Prerequisites

Before you can use GitHub Actions, you need:

1. **Repository on GitHub** - Your code must be in a GitHub repository
2. **Permissions** - You need write access to the repository
3. **GitHub Actions enabled** - Usually enabled by default

### Step 1: Verify Workflows Exist

After running `arc-setup` in your project, verify the workflows are present:

```bash
# Check if workflows directory exists
ls -la .github/workflows/

# You should see:
# quality.yml
# tests.yml
# docs.yml
```

If the workflows don't exist, ARCDevTools has them in:
```
Sources/ARCDevTools/Resources/Templates/GitHub/workflows/
```

You can copy them manually:
```bash
mkdir -p .github/workflows
cp path/to/ARCDevTools/Templates/GitHub/workflows/*.yml .github/workflows/
```

### Step 2: Push to GitHub

Workflows only run on code that's pushed to GitHub:

```bash
# Add workflows to git
git add .github/workflows/

# Commit
git commit -m "ci: add GitHub Actions workflows"

# Push to GitHub
git push origin main
```

### Step 3: Enable GitHub Actions

1. Go to your repository on GitHub
2. Click **Settings** → **Actions** → **General**
3. Under "Actions permissions", select **Allow all actions and reusable workflows**
4. Click **Save**

### Step 4: Verify Workflows Run

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You should see your workflows running or completed

## Viewing Workflow Results

### On GitHub Web Interface

**Step 1:** Go to the **Actions** tab in your repository

**Step 2:** Click on a workflow run to see details

**Step 3:** Click on a job to see step-by-step logs

**Example:**
```
Actions → All workflows → "Code Quality" → "SwiftLint"
  ✅ Checkout code
  ✅ Install SwiftLint
  ❌ Run SwiftLint (Click to see errors)
```

### Understanding Status Icons

- ✅ **Green checkmark** - Passed successfully
- ❌ **Red X** - Failed (click to see why)
- 🟡 **Yellow dot** - Currently running
- ⚪ **Gray circle** - Queued or skipped

### Reading Error Messages

When a workflow fails, click on the failed step:

```bash
# Example SwiftLint error
/Sources/MyFile.swift:42:5: warning: Line Length Violation
Line should be 120 characters or less: currently 145 characters

# Example test failure
❌ Test "versionIsCorrect" failed
Expected: 1.0.0
Got: 0.9.0
```

### Pull Request Checks

When you create a pull request, GitHub shows workflow status:

```
All checks have passed ✅
  ✅ SwiftLint
  ✅ SwiftFormat
  ✅ Test on macOS
  ✅ Test on Linux
```

You can configure branch protection to **require** these checks before merging.

## Configuring Workflows

### Changing When Workflows Run

Edit the `on:` section:

```yaml
# Run on every push
on: push

# Run only on specific branches
on:
  push:
    branches: [main, develop]

# Run on push and PRs
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

# Run on schedule (daily at 2am)
on:
  schedule:
    - cron: '0 2 * * *'

# Run manually
on:
  workflow_dispatch:
```

### Adding Notifications

Get Slack or email notifications when workflows fail:

```yaml
# At the end of a job
- name: Notify on failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text":"Build failed!"}'
```

### Caching Dependencies

Speed up workflows by caching Homebrew installations:

```yaml
- name: Cache Homebrew
  uses: actions/cache@v3
  with:
    path: ~/Library/Caches/Homebrew
    key: ${{ runner.os }}-brew-${{ hashFiles('**/Brewfile') }}

- name: Install SwiftLint
  run: brew install swiftlint
```

### Running on Different Swift Versions

Test against multiple Swift versions:

```yaml
jobs:
  test:
    strategy:
      matrix:
        swift: ['5.9', '6.0']
    runs-on: macos-latest
    steps:
      - name: Install Swift ${{ matrix.swift }}
        run: |
          # Download and install specific Swift version
```

## Setting Up Branch Protection

Require workflows to pass before merging:

### Step 1: Configure Protection Rules

1. Go to **Settings** → **Branches**
2. Click **Add rule** under "Branch protection rules"
3. Enter branch name pattern: `main`

### Step 2: Enable Required Checks

4. Check **Require status checks to pass before merging**
5. Search and select:
   - `SwiftLint`
   - `SwiftFormat`
   - `Test on macOS`
   - `Test on Linux`

6. Check **Require branches to be up to date**

### Step 3: Save Rules

7. Click **Create** or **Save changes**

**Result:** Pull requests can't be merged until all checks pass.

## Publishing Documentation to GitHub Pages

### Enable GitHub Pages

1. Go to **Settings** → **Pages**
2. Under **Source**, select **Deploy from a branch**
3. Select branch: `gh-pages`
4. Click **Save**

### Uncomment Deployment Step

Edit `.github/workflows/docs.yml`:

```yaml
# Remove the comment markers from these lines:
publish-docs:
  name: Publish to GitHub Pages
  needs: build-docs
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'

  steps:
    - name: Download documentation
      uses: actions/download-artifact@v4
      with:
        name: documentation
        path: docs/

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./docs
```

### Access Your Documentation

After the next push to `main`, your docs will be available at:
```
https://[username].github.io/[repository-name]/
```

## Troubleshooting CI/CD Issues

### Workflow Not Running

**Problem:** Pushed code but workflow didn't run

**Solutions:**

1. **Check Actions are enabled:**
   - Settings → Actions → General
   - Ensure "Allow all actions" is selected

2. **Check workflow syntax:**
   ```bash
   # Validate YAML syntax
   yamllint .github/workflows/*.yml
   ```

3. **Check branch name matches:**
   ```yaml
   # If workflow specifies:
   on:
     push:
       branches: [main]

   # But you pushed to 'master' or 'develop', it won't run
   ```

### Workflow Fails on macOS

**Problem:** `Error: No such file or directory - xcode-select`

**Solution:** Use correct Xcode version

```yaml
- name: Select Xcode
  run: |
    sudo xcode-select -s /Applications/Xcode_16.0.app/Contents/Developer
    # Or latest:
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### SwiftLint Fails with Unknown Rules

**Problem:** `Error: Unknown rule identifier 'some_rule'`

**Solution:** Rule might not exist in the SwiftLint version

```yaml
# Pin to specific version
- name: Install SwiftLint
  run: brew install swiftlint@0.52.0
```

Or remove the rule from `.swiftlint.yml`:
```yaml
disabled_rules:
  - unknown_rule_name
```

### Tests Fail Only in CI

**Problem:** Tests pass locally but fail in GitHub Actions

**Common causes:**

1. **Different Swift version**
   ```yaml
   # Specify exact Swift version
   runs-on: macos-13  # Swift 5.9
   runs-on: macos-14  # Swift 6.0
   ```

2. **Missing dependencies**
   ```yaml
   - name: Resolve dependencies
     run: swift package resolve
   ```

3. **Time-sensitive tests**
   ```swift
   // Don't use real time in tests
   let date = Date()  // ❌ Will vary
   let date = Date(timeIntervalSince1970: 0)  // ✅ Deterministic
   ```

### Workflow Takes Too Long

**Problem:** Workflow runs for 30+ minutes

**Solutions:**

1. **Enable caching:**
   ```yaml
   - uses: actions/cache@v3
     with:
       path: .build
       key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
   ```

2. **Run tests in parallel:**
   ```yaml
   - run: swift test --parallel
   ```

3. **Reduce matrix:**
   ```yaml
   # Instead of testing 10 Swift versions, test 2-3
   strategy:
     matrix:
       swift: ['5.9', '6.0']  # Reduced from ['5.7', '5.8', ...]
   ```

## Advanced Workflows

### Running Only on Changed Files

Only run SwiftLint on changed Swift files:

```yaml
- name: Get changed files
  id: changed-files
  uses: tj-actions/changed-files@v40
  with:
    files: |
      **/*.swift

- name: Run SwiftLint
  if: steps.changed-files.outputs.any_changed == 'true'
  run: |
    echo "${{ steps.changed-files.outputs.all_changed_files }}" | \
      xargs swiftlint lint --quiet
```

### Conditional Steps

Run different steps based on branch:

```yaml
- name: Run strict lint on main
  if: github.ref == 'refs/heads/main'
  run: swiftlint lint --strict

- name: Run relaxed lint on feature branches
  if: startsWith(github.ref, 'refs/heads/feature/')
  run: swiftlint lint
```

### Matrix Builds

Test multiple configurations:

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [macos-latest, ubuntu-latest]
        swift: ['5.9', '6.0']
    runs-on: ${{ matrix.os }}
    steps:
      - run: swift test
```

This creates 4 jobs:
- macOS + Swift 5.9
- macOS + Swift 6.0
- Ubuntu + Swift 5.9
- Ubuntu + Swift 6.0

## Best Practices

### Keep Workflows Fast

- Use caching for dependencies
- Run tests in parallel
- Only run necessary jobs
- Skip CI for documentation changes:
  ```yaml
  on:
    push:
      paths-ignore:
        - '**.md'
        - 'docs/**'
  ```

### Security Best Practices

1. **Never commit secrets to code**
   ```yaml
   # Use GitHub Secrets instead
   - run: curl -H "Authorization: Bearer ${{ secrets.API_TOKEN }}"
   ```

2. **Pin action versions**
   ```yaml
   # ❌ Unpredictable
   uses: actions/checkout@v4

   # ✅ Specific version
   uses: actions/checkout@v4.1.0
   ```

3. **Review third-party actions**
   ```yaml
   # Only use actions from trusted sources
   uses: actions/checkout@v4  # ✅ Official GitHub action
   uses: random-user/action@v1  # ⚠️  Review carefully
   ```

### Monitoring and Maintenance

- Review failed workflows weekly
- Update action versions monthly
- Archive old workflow runs
- Monitor workflow execution time

## Cost and Limits

### GitHub Actions Limits

**Free tier (Public repositories):**
- ✅ Unlimited minutes on public repos
- 2,000 minutes/month on private repos

**Paid tier:**
- Additional minutes available

**Runner limits:**
- macOS: 10x cost multiplier vs Linux
- Maximum 6 hours per workflow run
- Maximum 72 hours per workflow job

### Optimization Tips

```yaml
# Use Linux when possible (cheaper)
runs-on: ubuntu-latest  # ✅ Cheaper

# Only use macOS when necessary (Swift/Xcode)
runs-on: macos-latest   # More expensive, but needed for Xcode
```

## Next Steps

Now that you understand CI/CD:

1. **Review your workflows** - Check `.github/workflows/`
2. **Push code and observe** - Watch workflows run
3. **Set up branch protection** - Require checks before merging
4. **Customize as needed** - Adjust workflows for your needs

## See Also

- <doc:GettingStarted>
- <doc:Troubleshooting>
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
