#!/bin/bash
# =============================================================================
# ARC Labs Studio - Format on Save Hook (PostToolUse)
# =============================================================================
# Auto-formats .swift files after Edit/Write operations using SwiftFormat.
# Runs in ~50-100ms per file. Imperceptible to the user.
#
# Input: PostToolUse JSON on stdin (tool_name, tool_input, tool_response)
# Output: JSON feedback if formatting was applied
# =============================================================================

set -euo pipefail

INPUT=$(cat)

# Extract the file path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a Swift file
if [[ -z "$FILE_PATH" || "$FILE_PATH" != *.swift ]]; then
    exit 0
fi

# Skip if file doesn't exist (e.g., was deleted)
if [[ ! -f "$FILE_PATH" ]]; then
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
