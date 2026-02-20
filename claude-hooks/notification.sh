#!/bin/bash
# =============================================================================
# ARC Labs Studio - Notification Hook (Notification)
# =============================================================================
# Sends macOS notification when Claude Code needs attention.
# Triggers on: permission prompts, idle prompts, task completion.
#
# Input: Notification JSON on stdin (message, title, notification_type)
# =============================================================================

set -euo pipefail

INPUT=$(cat)

# Extract notification details from hook input
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs your attention"')

# Sanitize for osascript (escape quotes)
TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')

# Send macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\"" 2>/dev/null || true

exit 0
