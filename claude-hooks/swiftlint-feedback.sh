#!/bin/bash
# =============================================================================
# ARC Labs Studio - SwiftLint Feedback (PostToolUse)
# =============================================================================
# The most underrated hook pattern is feedback that TEACHES rather than just
# blocks. PostToolUse cannot block — the edit already happened — so instead of
# policing, this returns the concrete SwiftLint diagnostics for the file the
# agent just wrote, and the agent fixes them in the same turn instead of
# discovering them at commit time via the pre-commit git hook.
#
# Runs after format-on-save.sh, so it lints the formatted file.
#
# Config resolution, most specific first:
#   1. .swiftlint.yml walking up from the edited file to the repo root
#   2. ARCDevTools/configs/swiftlint.base.yml
#   3. SwiftLint's own defaults
#
# Silent when the file is clean, when SwiftLint isn't installed, or when the
# file isn't Swift — a hook that talks when it has nothing to say is noise.
#
# Input:  PostToolUse JSON on stdin (tool_name, tool_input, tool_response)
# Output: JSON additionalContext listing violations, or nothing
# =============================================================================

set -uo pipefail

MAX_VIOLATIONS=15

INPUT=$(cat)

FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" || "$FILE_PATH" != *.swift ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

SWIFTLINT=""
for candidate in swiftlint /opt/homebrew/bin/swiftlint /usr/local/bin/swiftlint; do
    if command -v "$candidate" &>/dev/null; then SWIFTLINT="$candidate"; break; fi
done
[[ -z "$SWIFTLINT" ]] && exit 0

# Walk up from the file looking for a project config.
CONFIG=""
DIR=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd) || exit 0
while [[ -n "$DIR" && "$DIR" != "/" ]]; do
    if [[ -f "$DIR/.swiftlint.yml" ]]; then CONFIG="$DIR/.swiftlint.yml"; break; fi
    [[ -d "$DIR/.git" ]] && break
    DIR=$(dirname "$DIR")
done
if [[ -z "$CONFIG" ]]; then
    BASE="$HOME/Developer/ARCLabsStudio/Packages/ARCDevTools/configs/swiftlint.base.yml"
    [[ -f "$BASE" ]] && CONFIG="$BASE"
fi

if [[ -n "$CONFIG" ]]; then
    OUTPUT=$("$SWIFTLINT" lint --quiet --config "$CONFIG" "$FILE_PATH" 2>/dev/null)
else
    OUTPUT=$("$SWIFTLINT" lint --quiet "$FILE_PATH" 2>/dev/null)
fi

# Keep only real diagnostics; stay quiet when the file is clean.
# Strip the absolute path prefix — the agent already knows which file it edited,
# and full paths burn context for nothing.
VIOLATIONS=$(printf '%s\n' "$OUTPUT" \
    | { grep -E ': (warning|error): ' || true; } \
    | sed "s|^${FILE_PATH}:|line |")
[[ -z "$VIOLATIONS" ]] && exit 0

COUNT=$(printf '%s\n' "$VIOLATIONS" | wc -l | tr -d ' ')
SHOWN=$(printf '%s\n' "$VIOLATIONS" | head -"$MAX_VIOLATIONS")

MESSAGE="SwiftLint found $COUNT issue(s) in $(basename "$FILE_PATH"):
$SHOWN"
if (( COUNT > MAX_VIOLATIONS )); then
    MESSAGE="$MESSAGE
… and $(( COUNT - MAX_VIOLATIONS )) more."
fi
MESSAGE="$MESSAGE

Fix these now — the pre-commit hook runs SwiftLint --strict and will reject the commit otherwise. ARC custom rules (observable_viewmodel, no_force_cast, no_force_try) encode constitution non-negotiables."

jq -n --arg ctx "$MESSAGE" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $ctx
  }
}'

exit 0
