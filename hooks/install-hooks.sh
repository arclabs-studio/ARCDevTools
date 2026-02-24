#!/bin/bash
# ARCDevTools - Instalador de Git Hooks
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_HOOKS_DIR=".git/hooks"

echo "🪝 Instalando git hooks de ARCDevTools..."

# Verificar que estamos en un repo git
if [ ! -d "$GIT_HOOKS_DIR" ]; then
  echo "❌ Error: No se encontró directorio .git/hooks"
  echo "   Ejecuta este script desde la raíz de un repositorio git"
  exit 1
fi

# Copiar pre-commit hook
if [ -f "$SCRIPT_DIR/pre-commit" ]; then
  cp "$SCRIPT_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
  chmod +x "$GIT_HOOKS_DIR/pre-commit"
  echo "✓ pre-commit hook instalado"
else
  echo "⚠️  No se encontró script pre-commit"
fi

# Copiar pre-push hook
if [ -f "$SCRIPT_DIR/pre-push" ]; then
  cp "$SCRIPT_DIR/pre-push" "$GIT_HOOKS_DIR/pre-push"
  chmod +x "$GIT_HOOKS_DIR/pre-push"
  echo "✓ pre-push hook instalado"
else
  echo "⚠️  No se encontró script pre-push"
fi

echo "✅ Git hooks instalados correctamente"
