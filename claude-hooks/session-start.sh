#!/bin/bash
# =============================================================================
# ARC Labs Studio - Session Start Hook (SessionStart)
# =============================================================================
# Shows project context when starting a Claude Code session:
# - Current branch
# - Pending changes
# - Last release tag
#
# Input: SessionStart JSON on stdin
# Output: JSON with additionalContext for Claude
# =============================================================================

set -euo pipefail

# Read stdin (required even if unused)
cat > /dev/null

# Nothing useful to report outside a git work tree — exit cleanly rather than
# letting a failing git call abort the hook under `set -o pipefail`.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Gather project context
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "no releases")
UNCOMMITTED=$(git diff --stat 2>/dev/null | tail -1 || echo "none")
STAGED=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "none")
RECENT=$(git log --oneline -5 2>/dev/null || echo "no commits")
# Each grep exits 1 on no match; under `set -o pipefail` that would abort the
# hook, so every stage is guarded individually.
MARKERS=$( { grep -rlE "TODO|FIXME" --include="*.swift" . 2>/dev/null || true; } \
    | { grep -vE "/(\.build|DerivedData|\.git)/" || true; } \
    | wc -l | tr -d ' ')

CONTEXT="Project context:
- Branch: $BRANCH
- Last release: $LAST_TAG
- Pending files: $CHANGES
- Uncommitted: $UNCOMMITTED
- Staged: $STAGED
- Open TODO/FIXME markers in Swift: $MARKERS
- Recent commits:
$RECENT"

# Output as JSON
jq -n --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ctx
  }
}'

exit 0
