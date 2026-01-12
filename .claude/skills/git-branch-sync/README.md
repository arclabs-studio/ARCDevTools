# Git Branch Sync

Synchronizes Git branches to the exact same commit point. Use when you need to bring one branch to the same point as another (e.g., syncing `develop` with `main` after a release).

## When to Use

- After creating a release tag on `main`
- When asked to "sync branches", "llevar al mismo punto", or "synchronize develop with main"
- Any time two branches need to point to the exact same commit

## Correct Process

**IMPORTANT:** Never use `git merge` when syncing branches to the same point. Merge creates an additional commit. Use `git reset --hard` instead.

### Steps

```bash
# 1. Checkout the branch to update
git checkout <branch-to-update>

# 2. Reset to target branch (HARD reset, not merge)
git reset --hard <target-branch>

# 3. Force push (required after reset)
git push origin <branch-to-update> --force

# 4. Verify both branches are at the same commit
git log --oneline -1 <target-branch> && git log --oneline -1 <branch-to-update>
```

### Example: Sync develop with main

```bash
git checkout develop
git reset --hard main
git push origin develop --force
git log --oneline -1 main && git log --oneline -1 develop
```

## Verification

After syncing, both branches MUST show the same commit SHA:

```
ab878f5 Merge branch 'feature/review' into main
ab878f5 Merge branch 'feature/review' into main
```

If the SHAs are different, the sync was not done correctly.

## Common Mistakes

| Wrong | Right |
|-------|-------|
| `git merge main` | `git reset --hard main` |
| `git push` | `git push --force` |
| Not verifying commits | Always verify with `git log` |

## Quick Reference

```bash
# One-liner to sync develop with main
git checkout develop && git reset --hard main && git push origin develop --force
```
