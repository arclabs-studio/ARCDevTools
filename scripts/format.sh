#!/bin/bash
# ARCDevTools - SwiftFormat Runner
# Version: 2.0.0
#
# Runs the *pinned* SwiftFormat (see configs/tool-versions) so local results
# match CI exactly.

set -e

CONFIG_FILE=".swiftformat"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Uso: $0 [--dry-run]"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./tool-env.sh
. "$SCRIPT_DIR/tool-env.sh"

echo "🎨 Ejecutando SwiftFormat..."

if [ -z "$SWIFTFORMAT_BIN" ]; then
  echo "❌ Error: SwiftFormat no está instalado"
  arc_tool_warn swiftformat
  exit 1
fi

arc_tool_warn swiftformat

if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Advertencia: No se encontró $CONFIG_FILE"
  echo "   Ejecutando con configuración por defecto..."
  CONFIG_ARG=""
else
  CONFIG_ARG="--config $CONFIG_FILE"
fi

if [ "$DRY_RUN" = true ]; then
  echo "   Modo: dry-run (sin cambios)"
  # shellcheck disable=SC2086
  "$SWIFTFORMAT_BIN" $CONFIG_ARG --lint .
else
  echo "   Modo: aplicar cambios"
  # shellcheck disable=SC2086
  "$SWIFTFORMAT_BIN" $CONFIG_ARG .
fi

echo "✅ SwiftFormat completado"
