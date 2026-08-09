#!/bin/bash
# ARCDevTools - Quality Tool Resolver
# Version: 1.0.0
#
# Sourced (not executed) by hooks, scripts and CI to resolve the *pinned*
# SwiftLint / SwiftFormat binaries so local runs and CI agree exactly.
#
#   source "path/to/tool-env.sh"
#   "$SWIFTLINT_BIN" lint --strict
#
# Exports:
#   ARC_REPO_ROOT         repo root
#   ARC_TOOLS_BIN         <repo>/.arc-tools/bin (pinned install location)
#   SWIFTLINT_VERSION     pinned version
#   SWIFTFORMAT_VERSION   pinned version
#   SWIFTLINT_BIN         path to a matching swiftlint, or "" if unavailable
#   SWIFTFORMAT_BIN       path to a matching swiftformat, or "" if unavailable
#   SWIFTLINT_STATUS      pinned | drift | missing
#   SWIFTFORMAT_STATUS    pinned | drift | missing
#
# Resolution order per tool:
#   1. <repo>/.arc-tools/bin/<tool>  if its version matches the pin
#   2. <tool> on PATH                if its version matches the pin
#   3. <tool> on PATH (any version)  -> status "drift" (caller decides)
#   4. nothing                       -> status "missing"

# --- locate repo root -------------------------------------------------------

ARC_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ARC_TOOLS_BIN="$ARC_REPO_ROOT/.arc-tools/bin"

# --- load pinned versions ---------------------------------------------------
# Prefer the copy inside the consumer project, fall back to this repo's config
# (covers running the scripts directly from ARCDevTools itself).

# BASH_SOURCE is unset under zsh; fall back to repo-relative lookups there.
_arc_tool_env_dir=""
if [ -n "${BASH_SOURCE:-}" ]; then
  _arc_tool_env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

ARC_TOOL_VERSIONS_FILE=""
for _candidate in \
  "$ARC_REPO_ROOT/.arc-tool-versions" \
  "$ARC_REPO_ROOT/ARCDevTools/configs/tool-versions" \
  "$ARC_REPO_ROOT/configs/tool-versions" \
  "${_arc_tool_env_dir:-.}/../configs/tool-versions"; do
  if [ -f "$_candidate" ]; then
    ARC_TOOL_VERSIONS_FILE="$_candidate"
    break
  fi
done

SWIFTLINT_VERSION=""
SWIFTFORMAT_VERSION=""

if [ -n "$ARC_TOOL_VERSIONS_FILE" ]; then
  # shellcheck disable=SC1090
  . "$ARC_TOOL_VERSIONS_FILE"
fi

# --- resolution -------------------------------------------------------------

# _arc_version_of <binary> <tool>
# Prints the bare semantic version reported by the binary.
_arc_version_of() {
  local bin="$1" tool="$2" out=""
  case "$tool" in
    swiftlint)   out="$("$bin" version 2>/dev/null)" ;;
    swiftformat) out="$("$bin" --version 2>/dev/null)" ;;
  esac
  printf '%s' "$out" | tr -d '[:space:]'
}

# _arc_resolve <tool> <pinned-version>
# Echoes "<status> <path>".
_arc_resolve() {
  local tool="$1" pinned="$2" candidate=""

  candidate="$ARC_TOOLS_BIN/$tool"
  if [ -x "$candidate" ] && [ -n "$pinned" ] && [ "$(_arc_version_of "$candidate" "$tool")" = "$pinned" ]; then
    echo "pinned $candidate"
    return
  fi

  candidate="$(command -v "$tool" 2>/dev/null || true)"
  if [ -n "$candidate" ]; then
    if [ -n "$pinned" ] && [ "$(_arc_version_of "$candidate" "$tool")" = "$pinned" ]; then
      echo "pinned $candidate"
    else
      echo "drift $candidate"
    fi
    return
  fi

  echo "missing "
}

read -r SWIFTLINT_STATUS SWIFTLINT_BIN <<<"$(_arc_resolve swiftlint "$SWIFTLINT_VERSION")"
read -r SWIFTFORMAT_STATUS SWIFTFORMAT_BIN <<<"$(_arc_resolve swiftformat "$SWIFTFORMAT_VERSION")"

# --- reporting helpers ------------------------------------------------------

# arc_tool_warn <tool>
# Prints a one-off drift/missing warning with the exact remedy.
arc_tool_warn() {
  # NOTE: `status` is read-only in zsh — use prefixed locals so this stays
  # safe when a developer sources the file from an interactive shell.
  local tool="$1" _status _bin pinned actual
  case "$tool" in
    swiftlint)   _status="$SWIFTLINT_STATUS";   _bin="$SWIFTLINT_BIN";   pinned="$SWIFTLINT_VERSION" ;;
    swiftformat) _status="$SWIFTFORMAT_STATUS"; _bin="$SWIFTFORMAT_BIN"; pinned="$SWIFTFORMAT_VERSION" ;;
    *) return 0 ;;
  esac

  case "$_status" in
    drift)
      actual="$(_arc_version_of "$_bin" "$tool")"
      echo "  ⚠️  $tool $actual found, but this project is pinned to $pinned."
      echo "      CI runs $pinned — results here may not match."
      echo "      Fix: ./ARCDevTools/scripts/install-tools.sh   (or: make tools)"
      ;;
    missing)
      echo "  ⚠️  $tool not installed (pinned version: ${pinned:-unknown})."
      echo "      Fix: ./ARCDevTools/scripts/install-tools.sh   (or: make tools)"
      ;;
  esac
}

unset _arc_tool_env_dir _candidate
