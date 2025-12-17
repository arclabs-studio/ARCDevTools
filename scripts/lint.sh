#!/bin/bash
# ARCDevTools - SwiftLint Runner
# Version: 1.0.0

set -e

CONFIG_FILE=".swiftlint.yml"

echo "🔍 Ejecutando SwiftLint..."

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "❌ Error: SwiftLint no está instalado"
  echo "   Instala con: brew install swiftlint"
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Advertencia: No se encontró $CONFIG_FILE"
  echo "   Ejecutando con configuración por defecto..."
  swiftlint lint
else
  swiftlint lint --config "$CONFIG_FILE"
fi

echo "✅ SwiftLint completado"
