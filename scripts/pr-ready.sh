#!/bin/bash
# ARCDevTools PR Ready Check
# Ejecuta todas las verificaciones del CI localmente
# Version: 2.0.0
#
# Usa las versiones *fijadas* de SwiftLint/SwiftFormat (configs/tool-versions)
# para que el resultado local coincida con el del CI.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./tool-env.sh
. "$SCRIPT_DIR/tool-env.sh"

echo ""
echo "========================================================"
echo "  PR Ready Check - Verificando que el PR esta listo"
echo "========================================================"
echo ""
echo "  SwiftLint   ${SWIFTLINT_VERSION:-?} (${SWIFTLINT_STATUS})"
echo "  SwiftFormat ${SWIFTFORMAT_VERSION:-?} (${SWIFTFORMAT_STATUS})"
echo ""

FAILED=0

# 1. SwiftFormat
echo "[1/4] SwiftFormat..."
if [ -n "$SWIFTFORMAT_BIN" ]; then
  arc_tool_warn swiftformat
  if "$SWIFTFORMAT_BIN" --lint Sources/ Tests/ 2>/dev/null; then
    echo "      SwiftFormat OK"
  else
    echo "      SwiftFormat FALLO"
    echo "      Ejecuta: make fix"
    FAILED=1
  fi
else
  arc_tool_warn swiftformat
  FAILED=1
fi
echo ""

# 2. SwiftLint
echo "[2/4] SwiftLint..."
if [ -n "$SWIFTLINT_BIN" ]; then
  arc_tool_warn swiftlint
  if "$SWIFTLINT_BIN" lint --strict --quiet 2>/dev/null; then
    echo "      SwiftLint OK"
  else
    echo "      SwiftLint FALLO"
    echo "      Ejecuta: make lint para ver detalles"
    FAILED=1
  fi
else
  arc_tool_warn swiftlint
  FAILED=1
fi
echo ""

# 3. Build
echo "[3/4] Build..."
if swift build 2>/dev/null; then
  echo "      Build OK"
else
  echo "      Build FALLO"
  FAILED=1
fi
echo ""

# 4. Tests
echo "[4/4] Tests..."
if swift test --parallel 2>/dev/null; then
  echo "      Tests OK"
else
  echo "      Tests FALLARON"
  FAILED=1
fi
echo ""

echo "========================================================"
if [ $FAILED -eq 0 ]; then
  echo "  PR listo para enviar!"
  echo "========================================================"
  exit 0
else
  echo "  Hay problemas que resolver antes de enviar el PR"
  echo "========================================================"
  exit 1
fi
