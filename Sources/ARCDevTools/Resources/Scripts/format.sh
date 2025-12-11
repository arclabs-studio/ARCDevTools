#!/bin/bash
# ARCDevTools - SwiftFormat Runner
# Version: 1.0.0

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

echo "🎨 Ejecutando SwiftFormat..."

if ! command -v swiftformat >/dev/null 2>&1; then
  echo "❌ Error: SwiftFormat no está instalado"
  echo "   Instala con: brew install swiftformat"
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Advertencia: No se encontró $CONFIG_FILE"
  echo "   Ejecutando con configuración por defecto..."
  CONFIG_ARG=""
else
  CONFIG_ARG="--config $CONFIG_FILE"
fi

if [ "$DRY_RUN" = true ]; then
  echo "   Modo: dry-run (sin cambios)"
  swiftformat $CONFIG_ARG --lint .
else
  echo "   Modo: aplicar cambios"
  swiftformat $CONFIG_ARG .
fi

echo "✅ SwiftFormat completado"
