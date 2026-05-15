#!/bin/bash
# =============================================================================
# ARC Labs Studio - asc CLI Mutation Guard (PreToolUse)
# =============================================================================
# Blocks `asc` commands that mutate App Store Connect state unless the user
# explicitly opts in. Same pattern as block-dangerous-git.sh.
#
# Mutating verbs blocked:
#   asc submit ...
#   asc release ...                  (release / phased-release / pause / resume)
#   asc metadata push ...
#   asc pricing edit ...
#   asc reviews create-response ...
#   asc apps wall submit ...
#   asc workflow run ...             (workflows can hide submit/push/edit)
#
# Two ways to proceed:
#   1. Append --dry-run to the command (hook allows; asc shows what it would do)
#   2. Prefix with ASC_CONFIRMED=1 (hook allows; the actual mutation runs)
#
# Detection ignores:
#   - quoted strings (commit messages, --notes "submit for review")
#   - heredoc bodies
#   - bash comments
#
# Every blocked attempt is appended to ~/.claude/asc-mutation-attempts.log.
#
# Input: PreToolUse JSON on stdin (tool_name, tool_input)
# Output: deny JSON if blocked; nothing if allowed
# =============================================================================

set -euo pipefail

LOG_FILE="$HOME/.claude/asc-mutation-attempts.log"
mkdir -p "$(dirname "$LOG_FILE")"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Strip heredoc bodies (cat <<'EOF' ... EOF)
CLEANED=$(echo "$COMMAND" | sed '/<<.*EOF/,/^[[:space:]]*EOF/d')
# Strip quoted strings (--notes "submit this build", echo 'asc submit')
CLEANED=$(echo "$CLEANED" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')
# Strip line comments
CLEANED=$(echo "$CLEANED" | sed 's/#.*$//')

# ─── Allow-list checks (return early before pattern matching) ────────────────

# `--dry-run` anywhere in the (cleaned) command → allow
if echo "$CLEANED" | grep -qE -- '(^|[[:space:]])--dry-run([[:space:]]|=|$)'; then
    exit 0
fi

# `ASC_CONFIRMED=1` (or true/yes) inline before the asc invocation → allow
if echo "$CLEANED" | grep -qE '(^|[[:space:]])ASC_CONFIRMED=(1|true|yes|on)([[:space:]]|$)'; then
    exit 0
fi

# ─── Detect mutating asc invocations ─────────────────────────────────────────
#
# Walk each pipeline segment (split on ; / && / || / |) and check whether the
# segment STARTS with an `asc` invocation matching a mutating verb. This
# avoids false positives when "asc submit" appears later in a pipeline that
# starts with grep/echo/etc.

MUTATING_PATTERN='^[[:space:]]*([A-Za-z_]+=[^[:space:]]+[[:space:]]+)*asc[[:space:]]+(submit|release|workflow[[:space:]]+run)([[:space:]]|$)'
MUTATING_PATTERN_2='^[[:space:]]*([A-Za-z_]+=[^[:space:]]+[[:space:]]+)*asc[[:space:]]+(metadata[[:space:]]+push|pricing[[:space:]]+edit|apps[[:space:]]+wall[[:space:]]+submit|reviews[[:space:]]+create-response)([[:space:]]|$)'

REASON=""
MATCHED_VERB=""

# Split CLEANED on shell separators into segments
# Replace separators with newlines for line-by-line iteration
SEGMENTS=$(echo "$CLEANED" | tr ';|&' '\n')

while IFS= read -r segment; do
    if [[ -z "$segment" ]]; then continue; fi
    if echo "$segment" | grep -qE "$MUTATING_PATTERN"; then
        MATCHED_VERB=$(echo "$segment" | grep -oE 'asc[[:space:]]+(submit|release|workflow[[:space:]]+run)' | head -1)
        REASON="Refusing to run \"$MATCHED_VERB\" because it mutates App Store Connect state."
        break
    fi
    if echo "$segment" | grep -qE "$MUTATING_PATTERN_2"; then
        MATCHED_VERB=$(echo "$segment" | grep -oE 'asc[[:space:]]+(metadata[[:space:]]+push|pricing[[:space:]]+edit|apps[[:space:]]+wall[[:space:]]+submit|reviews[[:space:]]+create-response)' | head -1)
        REASON="Refusing to run \"$MATCHED_VERB\" because it mutates App Store Connect state."
        break
    fi
done <<< "$SEGMENTS"

if [[ -z "$REASON" ]]; then
    exit 0
fi

# Build the full denial reason with bypass instructions
FULL_REASON="$REASON

Two ways to proceed (intentional friction — App Store mutations are slow or impossible to undo):

1. Dry-run first to see what would happen:
     ${MATCHED_VERB} … --dry-run

2. After review, set the sentinel inline for the actual mutation:
     ASC_CONFIRMED=1 ${MATCHED_VERB} …

This guard exists because submission queues, store-listing changes, and
pricing edits cannot be reversed quickly. See config/CLAUDE.md \"Destructive
command guard\" section."

# Log the attempt
{
    printf '[%s] BLOCKED: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$COMMAND"
} >> "$LOG_FILE" 2>/dev/null || true

# Emit deny JSON in the same shape as block-dangerous-git.sh
jq -n --arg reason "$FULL_REASON" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'

exit 0
