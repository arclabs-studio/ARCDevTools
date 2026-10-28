#!/bin/bash
# =============================================================================
# ARC Labs Studio - Xcode MCP Only (PreToolUse)  [OPT-IN]
# =============================================================================
# The constitution's strictest tooling rule — "Xcode MCP is the default; do not
# run xcodebuild/swift build/swift test/swiftc/simctl unless the user asks for
# the CLI by name" — is instruction-only, which means it holds *probably*.
# This hook makes it hold *always*.
#
# OPT-IN: not wired in the global settings.json, because ARC's own CI, ASC and
# benchmark scripts legitimately shell out to these tools. Enable it per project
# by adding it to that project's .claude/settings.json under PreToolUse/Bash.
#
# Escape hatch: set ARC_CLI_OK=1 in the command when the user has explicitly
# asked for the CLI path by name, e.g.
#   ARC_CLI_OK=1 xcodebuild -scheme MyApp test
#
# Allowed regardless: `swift package`, `swift run`, and anything invoked from a
# script inside the repo's own scripts/ directory.
#
# Input:  PreToolUse JSON on stdin
# Output: JSON with a deny decision when an Xcode CLI is used directly
# =============================================================================

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Explicit user consent for this invocation
echo "$COMMAND" | grep -qE '(^|[[:space:]])ARC_CLI_OK=1' && exit 0

CLEANED=$(echo "$COMMAND" | sed '/<<.*EOF/,/^[[:space:]]*EOF/d')

REASON=""

if echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*xcodebuild\b'; then
    REASON="'xcodebuild' is blocked. Build and test through the Xcode MCP (mcp__xcode__*, backed by xcrun mcpbridge) — consult the arc-mcp-xcode skill first."
fi

if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*swift\s+(build|test)\b'; then
    REASON="'swift build' / 'swift test' are blocked. Build and test through the Xcode MCP — consult the arc-mcp-xcode skill first. ('swift package' and 'swift run' are allowed.)"
fi

if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*swiftc\b'; then
    REASON="'swiftc' is blocked. Compile through the Xcode MCP — consult the arc-mcp-xcode skill first."
fi

if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*xcrun\s+simctl\b'; then
    REASON="'xcrun simctl' is blocked. Drive the simulator through the Xcode MCP, or delegate to the arc-verify-ui agent."
fi

if [[ -z "$REASON" ]] && echo "$CLEANED" | grep -qE '(^|&&|;|\||\$\()\s*xcodegen\b'; then
    REASON="'xcodegen' is blocked. Project structure changes go through Xcode or the Xcode MCP — never a generated pbxproj."
fi

[[ -z "$REASON" ]] && exit 0

REASON="$REASON

If the user explicitly asked for the CLI path by name, prefix the command with ARC_CLI_OK=1. \"Build the project\" or \"run the tests\" is not CLI consent."

jq -n --arg reason "$REASON" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'

exit 0
