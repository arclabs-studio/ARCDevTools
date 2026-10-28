#!/bin/bash
# =============================================================================
# ARC Labs Studio - Secrets Commit Guard (PreToolUse)
# =============================================================================
# protect-sensitive-files.sh stops the agent EDITING a secrets file. Nothing
# stopped a secret reaching a commit through an ordinary source file. This hook
# scans the STAGED DIFF whenever a `git commit` is about to run.
#
# Ships in ASK mode, not DENY: secret scanning has false positives (test
# fixtures, documentation examples, base64 blobs). "ask" surfaces the finding
# and lets the user decide. Harden to "deny" once the false-positive rate on
# real ARC repos is known — change DECISION below.
#
# Placeholders are exempt: values that are obviously fake (xxx, changeme,
# your-key-here, <...>, ${...}, TODO) do not trip the guard.
#
# Input:  PreToolUse JSON on stdin (tool_name, tool_input)
# Output: JSON with an ask decision when the staged diff looks like it carries
#         a credential
# =============================================================================

set -euo pipefail

DECISION="ask"   # "ask" (default) or "deny" once tuned

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Only act on an actual git commit, ignoring heredoc bodies and quoted prose
CLEANED=$(echo "$COMMAND" | sed '/<<.*EOF/,/^[[:space:]]*EOF/d')
printf '%s\n' "$CLEANED" | grep -qE '(^|&&|;|\|)\s*git\s+commit\b' || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# `git commit -a` stages tracked changes at commit time, so scan both.
if printf '%s\n' "$CLEANED" | grep -qE '\bgit\s+commit\s+(-[a-zA-Z]*a|--all)\b'; then
    DIFF=$(git diff HEAD 2>/dev/null || true)
else
    DIFF=$(git diff --cached 2>/dev/null || true)
fi
[[ -z "$DIFF" ]] && exit 0

# Added lines only — removing a leaked secret must never be blocked.
ADDED=$(printf '%s\n' "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+' || true)
[[ -z "$ADDED" ]] && exit 0

# Drop obvious placeholders before matching
CANDIDATES=$(printf '%s\n' "$ADDED" | grep -vEi 'xxx+|changeme|your[-_]?(api[-_]?)?key|placeholder|example\.com|<[^>]+>|\$\{[^}]+\}|TODO|FIXME|REDACTED|\*\*\*' || true)
[[ -z "$CANDIDATES" ]] && exit 0

FINDINGS=""
add_finding() { FINDINGS="${FINDINGS}  - $1"$'\n'; }

# Known-prefix provider tokens (high confidence)
printf '%s\n' "$CANDIDATES" | grep -qE '\b(sk-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,})' \
    && add_finding "a provider API token (OpenAI/GitHub/Slack/AWS/Google prefix)" || true

# Private key blocks
printf '%s\n' "$CANDIDATES" | grep -qE 'BEGIN [A-Z ]*PRIVATE KEY' \
    && add_finding "a PEM private key block" || true

# Assignment of a long opaque literal to a secret-shaped name
printf '%s\n' "$CANDIDATES" | grep -qEi '(api[-_]?key|secret|passwd|password|token|client[-_]?secret|auth[-_]?key)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{12,}["'"'"']' \
    && add_finding "a credential-shaped assignment with a long literal value" || true

# JWTs
printf '%s\n' "$CANDIDATES" | grep -qE '\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
    && add_finding "what looks like a signed JWT" || true

[[ -z "$FINDINGS" ]] && exit 0

REASON="Staged changes may contain a credential:
${FINDINGS}
Secrets belong in the macOS Keychain, never in source, logs or commits — see the constitution's Non-negotiables. Inspect with 'git diff --cached' before continuing. If this is a fixture or a documentation example, use an obvious placeholder so the guard stays useful."

jq -n --arg reason "$REASON" --arg decision "$DECISION" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": $decision,
    "permissionDecisionReason": $reason
  }
}'

exit 0
