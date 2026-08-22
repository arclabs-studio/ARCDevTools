#!/bin/bash
# =============================================================================
# ARC Labs Studio - Stop Build Gate (Stop)  [OPT-IN]
# =============================================================================
# "Green before done": when a session has touched Swift files, verify the
# project still builds with 0 errors and 0 warnings before Claude is allowed to
# finish its turn. exit 2 sends Claude back to work with the diagnostics.
#
# This is the deterministic form of the constitution's definition of done, and
# the hard version of the prime directive "iterate against an external verifier".
#
# OPT-IN and DELIBERATELY NOT WIRED GLOBALLY. It fires at the end of EVERY
# response and a build costs 10-60s. Enable per project in that project's
# .claude/settings.json under "Stop", and set BUILD_CMD below first —
# autodetection is unreliable in workspaces.
#
# Relationship to ARCDevTools' own prompt-type Stop hook: that one asks a small
# model to typecheck edited files (cheap, catches syntax). This one is the hard
# gate that also fails on warnings. Run one or the other, not both.
#
# Loop safety: honours stop_hook_active (the runtime caps consecutive blocks).
# =============================================================================

set -uo pipefail

INPUT=$(cat)

STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
# Already blocked once this stop cycle — let it through rather than loop.
[[ "$STOP_ACTIVE" == "true" ]] && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Only gate when there are uncommitted Swift changes.
git status --porcelain 2>/dev/null | grep -qE '\.swift$' || exit 0

# --- CONFIGURE PER PROJECT (pick one, delete the rest) ----------------------
BUILD_CMD="swift build"
# Xcode project — hardcode the scheme; autodetection is unreliable:
# BUILD_CMD="xcodebuild -scheme MyApp -destination 'generic/platform=iOS Simulator' build"
# ---------------------------------------------------------------------------

LOG=$(eval "$BUILD_CMD" 2>&1)
STATUS=$?

if [[ $STATUS -ne 0 ]] || echo "$LOG" | grep -q ": warning:"; then
    {
        echo "BLOCKED — definition of done: the project must build with 0 errors and 0 warnings before you finish."
        echo "$LOG" | grep -E ": (error|warning):" | head -15
    } >&2
    exit 2
fi

exit 0
