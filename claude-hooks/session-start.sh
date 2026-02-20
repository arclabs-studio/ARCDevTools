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

# Gather project context
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "no releases")
UNCOMMITTED=$(git diff --stat 2>/dev/null | tail -1 || echo "none")
STAGED=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "none")

CONTEXT="Project context:
- Branch: $BRANCH
- Last release: $LAST_TAG
- Pending files: $CHANGES
- Uncommitted: $UNCOMMITTED
- Staged: $STAGED"

# Output as JSON
jq -n --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ctx
  }
}'

exit 0
