#!/bin/bash
# ARCDevTools - Pinned Quality Tool Installer
# Version: 1.0.0
#
# Installs the exact SwiftLint / SwiftFormat versions pinned in
# `configs/tool-versions` (or the project's `.arc-tool-versions`) into
# `<repo>/.arc-tools/bin`, so developer machines, GitHub Actions and Xcode
# Cloud all run byte-identical linters.
#
# Deliberately does NOT use Homebrew: brew has no versioned formula for these
# tools, so `brew install swiftlint` silently drifts to whatever is latest.
#
# Usage:
#   ./ARCDevTools/scripts/install-tools.sh              # install both
#   ./ARCDevTools/scripts/install-tools.sh swiftlint    # one tool
#   ./ARCDevTools/scripts/install-tools.sh --force      # reinstall
#
# Idempotent: a tool already present at the pinned version is left alone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TOOLS_DIR="$REPO_ROOT/.arc-tools"
BIN_DIR="$TOOLS_DIR/bin"

FORCE=false
WANTED=()

for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=true ;;
    swiftlint|swiftformat) WANTED+=("$arg") ;;
    -h|--help)
      sed -n '2,20p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

if [ ${#WANTED[@]} -eq 0 ]; then
  WANTED=(swiftlint swiftformat)
fi

# --- pinned versions --------------------------------------------------------

VERSIONS_FILE=""
for candidate in \
  "$REPO_ROOT/.arc-tool-versions" \
  "$REPO_ROOT/ARCDevTools/configs/tool-versions" \
  "$SCRIPT_DIR/../configs/tool-versions"; do
  if [ -f "$candidate" ]; then
    VERSIONS_FILE="$candidate"
    break
  fi
done

if [ -z "$VERSIONS_FILE" ]; then
  echo "❌ No pinned tool versions found (.arc-tool-versions / configs/tool-versions)." >&2
  echo "   Run ./ARCDevTools/arcdevtools-setup to install it." >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$VERSIONS_FILE"

echo "🔧 ARCDevTools tool install"
echo "   Pins from: ${VERSIONS_FILE#"$REPO_ROOT"/}"
echo "   Target:    ${BIN_DIR#"$REPO_ROOT"/}"
echo ""

# --- platform ---------------------------------------------------------------

OS="$(uname -s)"
ARCH="$(uname -m)"

mkdir -p "$BIN_DIR"

# installed_version <tool>
installed_version() {
  local tool="$1" bin="$BIN_DIR/$1"
  [ -x "$bin" ] || return 1
  case "$tool" in
    swiftlint)   "$bin" version 2>/dev/null | tr -d '[:space:]' ;;
    swiftformat) "$bin" --version 2>/dev/null | tr -d '[:space:]' ;;
  esac
}

# fetch_zip <url> <dest-dir>
fetch_zip() {
  local url="$1" dest="$2"
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "$dest/download.zip" "$url"; then
    echo "❌ Download failed: $url" >&2
    return 1
  fi
  unzip -oq "$dest/download.zip" -d "$dest"
}

install_swiftlint() {
  local version="$1"
  local url binary tmp

  case "$OS" in
    Darwin)
      # Universal binary (x86_64 + arm64).
      url="https://github.com/realm/SwiftLint/releases/download/${version}/portable_swiftlint.zip"
      ;;
    Linux)
      case "$ARCH" in
        x86_64|amd64) url="https://github.com/realm/SwiftLint/releases/download/${version}/swiftlint_linux_amd64.zip" ;;
        aarch64|arm64) url="https://github.com/realm/SwiftLint/releases/download/${version}/swiftlint_linux_arm64.zip" ;;
        *) echo "❌ Unsupported Linux arch for SwiftLint: $ARCH" >&2; return 1 ;;
      esac
      ;;
    *)
      echo "❌ Unsupported OS for SwiftLint: $OS" >&2
      return 1
      ;;
  esac

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  echo "   ⬇️  SwiftLint $version"
  fetch_zip "$url" "$tmp"

  # Linux archives ship both a dynamically linked `swiftlint` (needs the Swift
  # runtime) and a self-contained `swiftlint-static`. Prefer the static one so
  # bare CI images work without installing Swift.
  if [ -x "$tmp/swiftlint-static" ]; then
    binary="$tmp/swiftlint-static"
  elif [ -x "$tmp/swiftlint" ]; then
    binary="$tmp/swiftlint"
  else
    binary="$(find "$tmp" -type f -name 'swiftlint*' -perm -u+x | head -1)"
  fi

  if [ -z "$binary" ]; then
    echo "❌ SwiftLint binary not found in archive" >&2
    return 1
  fi

  install -m 0755 "$binary" "$BIN_DIR/swiftlint"
}

install_swiftformat() {
  local version="$1"
  local url binary tmp

  case "$OS" in
    Darwin)
      url="https://github.com/nicklockwood/SwiftFormat/releases/download/${version}/swiftformat.zip"
      ;;
    Linux)
      case "$ARCH" in
        x86_64|amd64) url="https://github.com/nicklockwood/SwiftFormat/releases/download/${version}/swiftformat_linux.zip" ;;
        aarch64|arm64) url="https://github.com/nicklockwood/SwiftFormat/releases/download/${version}/swiftformat_linux_aarch64.zip" ;;
        *) echo "❌ Unsupported Linux arch for SwiftFormat: $ARCH" >&2; return 1 ;;
      esac
      ;;
    *)
      echo "❌ Unsupported OS for SwiftFormat: $OS" >&2
      return 1
      ;;
  esac

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  echo "   ⬇️  SwiftFormat $version"
  fetch_zip "$url" "$tmp"

  binary="$(find "$tmp" -type f -name 'swiftformat*' ! -name '*.zip' | head -1)"
  if [ -z "$binary" ]; then
    echo "❌ SwiftFormat binary not found in archive" >&2
    return 1
  fi

  install -m 0755 "$binary" "$BIN_DIR/swiftformat"
}

# --- run --------------------------------------------------------------------

for tool in "${WANTED[@]}"; do
  case "$tool" in
    swiftlint)   pinned="${SWIFTLINT_VERSION:-}" ;;
    swiftformat) pinned="${SWIFTFORMAT_VERSION:-}" ;;
  esac

  if [ -z "$pinned" ]; then
    echo "❌ No pinned version for $tool in $VERSIONS_FILE" >&2
    exit 1
  fi

  current="$(installed_version "$tool" || true)"
  if [ "$FORCE" = false ] && [ "$current" = "$pinned" ]; then
    echo "   ✅ $tool $pinned already installed"
    continue
  fi

  "install_$tool" "$pinned"

  current="$(installed_version "$tool" || true)"
  if [ "$current" != "$pinned" ]; then
    echo "❌ $tool reports '$current' after install, expected '$pinned'" >&2
    exit 1
  fi
  echo "   ✅ $tool $pinned installed"
done

echo ""
echo "✅ Pinned tools ready in ${BIN_DIR#"$REPO_ROOT"/}"
echo "   Hooks, make targets and CI resolve them automatically."
echo "   To use them in your shell: export PATH=\"\$PWD/.arc-tools/bin:\$PATH\""
