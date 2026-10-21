#!/bin/bash
# =============================================================================
# ARC Labs Studio - Format on Save Hook (PostToolUse)
# =============================================================================
# Auto-formats .swift files after Edit/Write operations using SwiftFormat, and
# .kt/.kts files with ktlint (only when `ktlint` is on PATH; otherwise no-op).
# Runs in ~50-100ms per Swift file. Imperceptible to the user.
#
# Input: PostToolUse JSON on stdin (tool_name, tool_input, tool_response)
# Output: JSON feedback if formatting was applied
# =============================================================================

set -euo pipefail

INPUT=$(cat)

# Extract the file path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a Swift/Kotlin file
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi
case "$FILE_PATH" in
    *.swift|*.kt|*.kts) ;;
    *) exit 0 ;;
esac

# Skip if file doesn't exist (e.g., was deleted)
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Kotlin: ktlint --format (Android projects). No-op when ktlint is not installed.
# ktlint takes gitignore-style globs relative to the working directory, so run it
# from the file's directory with the bare file name. Exit 0 = clean, 1 = formatted
# but violations remain (reported by the build gates, not here).
if [[ "$FILE_PATH" == *.kt || "$FILE_PATH" == *.kts ]]; then
    command -v ktlint &>/dev/null || exit 0
    KT_STATUS=0
    (cd "$(dirname "$FILE_PATH")" && ktlint --format --log-level=none "$(basename "$FILE_PATH")") \
        >/dev/null 2>&1 || KT_STATUS=$?
    if [[ "$KT_STATUS" -le 1 ]]; then
        echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"ktlint format applied to '"$FILE_PATH"'"}}'
    fi
    exit 0
fi

# Find SwiftFormat binary
SWIFTFORMAT=""
if command -v swiftformat &>/dev/null; then
    SWIFTFORMAT="swiftformat"
elif [[ -x /opt/homebrew/bin/swiftformat ]]; then
    SWIFTFORMAT="/opt/homebrew/bin/swiftformat"
elif [[ -x /usr/local/bin/swiftformat ]]; then
    SWIFTFORMAT="/usr/local/bin/swiftformat"
fi

if [[ -z "$SWIFTFORMAT" ]]; then
    exit 0
fi

# Run SwiftFormat on the file
if $SWIFTFORMAT "$FILE_PATH" --quiet 2>/dev/null; then
    echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"SwiftFormat applied to '"$FILE_PATH"'"}}'
fi

exit 0
