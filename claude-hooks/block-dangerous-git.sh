#!/bin/bash
# =============================================================================
# ARC Labs Studio - Block Dangerous Git Commands (PreToolUse)
# =============================================================================
# Blocks destructive git operations:
# - git push --force to main/develop
# - git clean -f (removes untracked files)
# - git reset --hard (discards all changes)
# - git branch -D main/develop (delete protected branches)
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

REASON=""

# Block: git push --force to main or develop
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|develop|master)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+.*-f\s+.*\s+(main|develop|master)' || \
   echo "$COMMAND" | grep -qE 'git\s+push\s+--force.*origin\s+(main|develop|master)'; then
    REASON="Force push to protected branch (main/develop) is blocked. This is a destructive operation that can overwrite upstream history."
fi

# Block: git clean -f (without dry-run)
if [[ -z "$REASON" ]] && echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f' && \
   ! echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*n'; then
    REASON="git clean -f is blocked. This permanently removes untracked files. Use 'git clean -n' first to preview what would be removed."
fi

# Block: git reset --hard (without specific file)
if [[ -z "$REASON" ]] && echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    REASON="git reset --hard is blocked. This discards all uncommitted changes. Consider 'git stash' instead to preserve your work."
fi

# Block: git branch -D main/develop
if [[ -z "$REASON" ]] && echo "$COMMAND" | grep -qE 'git\s+branch\s+-D\s+(main|develop|master)'; then
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
