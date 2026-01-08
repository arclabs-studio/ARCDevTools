#!/bin/bash
# ARCDevTools PR Ready Check
# Ejecuta todas las verificaciones del CI localmente
# Version: 1.0.0

set -e

echo ""
echo "========================================================"
echo "  PR Ready Check - Verificando que el PR esta listo"
echo "========================================================"
echo ""

FAILED=0

# 1. SwiftFormat
echo "[1/4] SwiftFormat..."
if command -v swiftformat >/dev/null 2>&1; then
  if swiftformat --lint Sources/ Tests/ 2>/dev/null; then
    echo "      SwiftFormat OK"
  else
    echo "      SwiftFormat FALLO"
    echo "      Ejecuta: swiftformat Sources/ Tests/"
    FAILED=1
  fi
else
  echo "      SwiftFormat no instalado (brew install swiftformat)"
  FAILED=1
fi
echo ""

# 2. SwiftLint
echo "[2/4] SwiftLint..."
if command -v swiftlint >/dev/null 2>&1; then
  if swiftlint lint --strict --quiet 2>/dev/null; then
    echo "      SwiftLint OK"
  else
    echo "      SwiftLint FALLO"
    echo "      Ejecuta: swiftlint lint para ver detalles"
    FAILED=1
  fi
else
  echo "      SwiftLint no instalado (brew install swiftlint)"
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
