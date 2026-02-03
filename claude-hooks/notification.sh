#!/bin/bash
# =============================================================================
# ARC Labs Studio - Notification Hook
# =============================================================================
# Sends macOS notification when Claude Code completes a task
# =============================================================================

set -euo pipefail

INPUT=$(cat)

# Extract notification details
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Task completed"')

# Send macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Glass\""
