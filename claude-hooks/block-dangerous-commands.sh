#!/bin/bash
# =============================================================================
# ARC Labs Studio - Block Dangerous Shell Commands (PreToolUse)
# =============================================================================
# Complements block-dangerous-git.sh, which only covers git. This one covers
# the destructive shell primitives:
# - rm -rf / rm -fr (recursive force delete)
# - sudo rm (privileged delete)
# - chmod 777 (world-writable)
# - redirection into .env files (clobbers secrets)
# - curl|wget piped into a shell (remote code execution)
# - dd writing to a device, mkfs (disk destruction)
#
# Only matches actual commands, not strings that mention them inside heredocs,
# commit messages, echo statements or PR bodies.
#
# Semantics: PreToolUse "deny" blocks the call and returns the reason to the
# model as feedback. A deny here applies even under bypassPermissions, which is
# why the critical rules live in hooks rather than in CLAUDE.md.
#
# Input:  PreToolUse JSON on stdin (tool_name, tool_input)
# Output: JSON with a deny decision if the command is dangerous
# =============================================================================

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Strip heredoc bodies so quoted prose never triggers a block
CLEANED=$(echo "$COMMAND" | sed '/<<.*EOF/,/^[[:space:]]*EOF/d')

REASON=""

# --- Recursive force delete -------------------------------------------------
if echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*(sudo\s+)?rm\s+(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])'; then
    REASON="'rm -rf' is blocked. Delete specific paths without -r/-f, move the target to a scratch directory, or ask the user to run it themselves."
fi

# --- Privileged delete ------------------------------------------------------
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*sudo\s+rm\b'; then
    REASON="'sudo rm' is blocked. Privileged deletion is never an agent's call — ask the user."
fi

# --- World-writable permissions --------------------------------------------
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*(sudo\s+)?chmod\s+(-[a-zA-Z]+\s+)*777\b'; then
    REASON="'chmod 777' is blocked. Grant the narrowest permission that works (755 for executables, 644 for files)."
fi

# --- Clobbering a secrets file ---------------------------------------------
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '>{1,2}\s*[^ ]*\.env(\.[a-zA-Z0-9_-]+)?(\s|$)'; then
    REASON="Redirecting output into a .env file is blocked. Secrets live in the macOS Keychain — see the constitution's Non-negotiables."
fi

# --- Remote code execution --------------------------------------------------
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(curl|wget)\b[^|]*\|\s*(sudo\s+)?(ba|z|k)?sh\b'; then
    REASON="Piping a download straight into a shell is blocked. Download the script, read it, then run it — every agentic dependency that executes code is audited like production code."
fi

# --- Disk destruction -------------------------------------------------------
if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*(sudo\s+)?(mkfs(\.[a-z0-9]+)?|dd)\s' && \
   echo "$CLEANED" | grep -qE '(of=/dev/|mkfs)'; then
    REASON="Writing directly to a device (dd/mkfs) is blocked."
fi

[[ -z "$REASON" ]] && exit 0

jq -n --arg reason "$REASON" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'

exit 0
