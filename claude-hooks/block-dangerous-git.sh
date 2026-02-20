#!/bin/bash
# =============================================================================
# ARC Labs Studio - Block Dangerous Git Commands (PreToolUse)
# =============================================================================
# Blocks destructive git operations:
# - git push --force to main/develop
# - git clean -f (removes untracked files)
# - git reset --hard (discards all changes, unless targeting origin/*)
# - git branch -D main/develop (delete protected branches)
#
# Only matches actual git commands, not strings that mention git commands
# inside heredocs, commit messages, echo statements, or PR bodies.
#
# Input: PreToolUse JSON on stdin (tool_name, tool_input)
# Output: JSON with deny decision if command is dangerous
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

# Extract only actual git commands from the pipeline, ignoring:
# - Content inside quotes (commit messages, PR bodies, echo strings)
# - Heredoc bodies (cat <<'EOF' ... EOF)
# - Comments
#
# Strategy: split on && / ; / | and check each segment for a git command
# that starts at the beginning of the segment (after whitespace).

# Strip heredoc content (everything between <<'EOF'/<<"EOF"/<<EOF and EOF)
CLEANED=$(echo "$COMMAND" | sed '/<<.*EOF/,/^[[:space:]]*EOF/d')

# Strip content inside double quotes and single quotes (simple approach)
# This handles: git commit -m "message with git reset --hard"
# and: gh pr create --body '... git push --force ...'
CLEANED=$(echo "$CLEANED" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

# Now check the cleaned command for dangerous patterns
REASON=""

# Block: git push --force to main or develop
if echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+push\s+.*--force.*\s+(main|develop|master)' || \
   echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+push\s+.*-f\s+.*\s+(main|develop|master)' || \
   echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+push\s+--force.*origin\s+(main|develop|master)'; then
    REASON="Force push to protected branch (main/develop) is blocked. This is a destructive operation that can overwrite upstream history."
fi

# Block: git clean -f (without dry-run)
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+clean\s+.*-[a-zA-Z]*f' && \
   ! echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+clean\s+.*-[a-zA-Z]*n'; then
    REASON="git clean -f is blocked. This permanently removes untracked files. Use 'git clean -n' first to preview what would be removed."
fi

# Block: git reset --hard (allow when targeting a remote tracking branch like origin/*)
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+reset\s+--hard' && \
   ! echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+reset\s+--hard\s+origin/'; then
    REASON="git reset --hard is blocked. This discards all uncommitted changes. Consider 'git stash' or 'git reset --hard origin/<branch>' instead."
fi

# Block: git branch -D main/develop
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+branch\s+-D\s+(main|develop|master)'; then
    REASON="Deleting protected branch (main/develop) is blocked."
fi

# If no dangerous command found, allow
if [[ -z "$REASON" ]]; then
    exit 0
fi

# Block the dangerous command
jq -n --arg reason "$REASON" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'

exit 0
