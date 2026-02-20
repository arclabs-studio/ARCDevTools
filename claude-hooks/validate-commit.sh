#!/bin/bash
# =============================================================================
# ARC Labs Studio - Validate Conventional Commits Hook (PreToolUse)
# =============================================================================
# Intercepts `git commit` commands and validates the commit message follows
# Conventional Commits format: type(scope): subject
#
# Valid types: feat, fix, docs, style, refactor, perf, test, chore, build, ci, revert
#
# Input: PreToolUse JSON on stdin (tool_name, tool_input)
# Output: JSON with deny decision if message is invalid
# =============================================================================

set -euo pipefail

INPUT=$(cat)

# Only process Bash tool calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

# Extract the command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only validate commands that START with git commit (ignoring leading whitespace)
# This avoids false positives from strings that mention "git commit" inside
# heredocs, echo statements, PR bodies, etc.
FIRST_CMD=$(echo "$COMMAND" | sed 's/^[[:space:]]*//')
if [[ "$FIRST_CMD" != "git commit"* ]]; then
    exit 0
fi

# Skip if it's an amend without a new message
if [[ "$COMMAND" == *"--amend"* && "$COMMAND" != *"-m"* ]]; then
    exit 0
fi

# Extract commit message from -m flag
# Handle both: git commit -m "message" and git commit -m "$(cat <<'EOF'...)"
COMMIT_MSG=""

# Try to extract from HEREDOC pattern (cat <<'EOF'...EOF)
if [[ "$COMMAND" == *"cat <<'EOF'"* || "$COMMAND" == *'cat <<"EOF"'* || "$COMMAND" == *"cat <<EOF"* ]]; then
    COMMIT_MSG=$(echo "$COMMAND" | sed -n '/cat <<.*EOF/,/EOF/p' | sed '1d;$d' | head -1 | sed 's/^[[:space:]]*//')
fi

# Try to extract from -m "message" or -m 'message'
if [[ -z "$COMMIT_MSG" ]]; then
    # Match -m "..." or -m '...'
    COMMIT_MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s")[^"]*' 2>/dev/null || \
                 echo "$COMMAND" | grep -oP "(?<=-m\s')[^']*" 2>/dev/null || \
                 echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || \
                 echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*'\([^']*\)'.*/\1/p" 2>/dev/null || \
                 echo "")
fi

# If we couldn't extract a message, allow (don't block on edge cases)
if [[ -z "$COMMIT_MSG" ]]; then
    exit 0
fi

# Strip leading whitespace
COMMIT_MSG=$(echo "$COMMIT_MSG" | sed 's/^[[:space:]]*//')

# Conventional Commits regex
# type(scope): subject  OR  type: subject
PATTERN='^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\([a-zA-Z0-9_-]+\))?!?:[[:space:]].+'

if echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    # Valid conventional commit
    exit 0
fi

# Invalid - block the commit
cat <<JSONEOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Commit message does not follow Conventional Commits format.\n\nGot: \"$COMMIT_MSG\"\n\nExpected format: type(scope): subject\n\nValid types: feat, fix, docs, style, refactor, perf, test, chore, build, ci, revert\n\nExamples:\n  feat(search): add restaurant filtering\n  fix(map): resolve annotation crash\n  docs(readme): update installation steps\n  chore(deps): update dependencies"
  }
}
JSONEOF

exit 0
