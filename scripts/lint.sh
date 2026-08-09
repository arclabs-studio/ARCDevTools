#!/bin/bash
# ARCDevTools - SwiftLint Runner
# Version: 2.0.0
#
# Runs the *pinned* SwiftLint (see configs/tool-versions) so local results
# match CI exactly.

set -e

CONFIG_FILE=".swiftlint.yml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./tool-env.sh
. "$SCRIPT_DIR/tool-env.sh"

echo "🔍 Ejecutando SwiftLint..."

if [ -z "$SWIFTLINT_BIN" ]; then
  echo "❌ Error: SwiftLint no está instalado"
  arc_tool_warn swiftlint
  exit 1
fi

arc_tool_warn swiftlint

if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Advertencia: No se encontró $CONFIG_FILE"
  echo "   Ejecutando con configuración por defecto..."
  "$SWIFTLINT_BIN" lint
else
  "$SWIFTLINT_BIN" lint --config "$CONFIG_FILE"
fi

echo "✅ SwiftLint completado"
