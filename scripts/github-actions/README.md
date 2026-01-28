# GitHub Actions - Claude Code Integration Scripts

Scripts para configurar y mantener la integración de Claude Code en todos los repositorios públicos de ARC Labs Studio.

## 📋 Scripts disponibles

### 🚀 Configuración inicial

#### `add-claude-workflows.sh`
**Uso:** Añade workflows de Claude a todos los repos públicos automáticamente.

```bash
./add-claude-workflows.sh
```

**Qué hace:**
- Clona cada repositorio público
- Crea `.github/workflows/claude.yml` y `claude-code-review.yml`
- Hace commit y push directamente a la rama principal
- ⚠️ Solo funciona en repos sin protección de ramas

---

#### `add-claude-workflows-interactive.sh`
**Uso:** Versión interactiva que permite seleccionar qué repos configurar.

```bash
./add-claude-workflows-interactive.sh
```

**Opciones de selección:**
- `a` - Todos los repositorios
- `1,2,3` - Repos específicos (separados por comas)
- `1-5` - Rango de repositorios
- `q` - Cancelar

---

#### `add-claude-workflows-via-pr.sh`
**Uso:** Añade workflows vía Pull Request (para repos con ramas protegidas).

```bash
./add-claude-workflows-via-pr.sh <repo-name1> <repo-name2> ...
```

**Ejemplo:**
```bash
./add-claude-workflows-via-pr.sh ARCUIComponents ARCDevTools ARCKnowledge
```

**Qué hace:**
- Crea una rama `chore/add-claude-workflows-<timestamp>`
- Añade los workflows
- Crea una PR con descripción detallada
- Requiere review y merge manual

---

### 🔐 Configuración de secrets

#### `setup-claude-secret-all-repos.sh`
**Uso:** Configura el secret `CLAUDE_CODE_OAUTH_TOKEN` en todos los repos.

```bash
./setup-claude-secret-all-repos.sh
```

**Qué hace:**
- Solicita tu Claude OAuth token (entrada oculta)
- Configura el secret en los 15 repositorios públicos
- Muestra resumen de éxito/errores

**Prerequisito:**
```bash
# Obtener el token primero
claude setup-token
```

---

### 🔧 Correcciones de permisos

#### `fix-claude-workflow-permissions-all-repos.sh`
**Uso:** Actualiza permisos `read` → `write` para `issues` y `pull-requests`.

```bash
./fix-claude-workflow-permissions-all-repos.sh
```

**Qué hace:**
- Actualiza permisos en `claude.yml`:
  - `pull-requests: write` (para comentar en PRs)
  - `issues: write` (para comentar en issues)
- Crea PRs automáticamente
- Intenta mergear las PRs al final

---

#### `fix-claude-contents-permission-all-repos.sh`
**Uso:** Actualiza permiso `contents: read` → `write`.

```bash
./fix-claude-contents-permission-all-repos.sh
```

**Qué hace:**
- Actualiza `contents: write` en `claude.yml`
- Permite a Claude crear ramas y commits
- Crea y mergea PRs automáticamente

---

## 📚 Workflows configurados

### `claude.yml`
Responde a menciones `@claude` en issues y PRs.

**Triggers:**
- Issue comments con `@claude`
- PR comments con `@claude`
- PR reviews con `@claude`
- Issues asignados con `@claude`

**Permisos necesarios:**
- `contents: write` - Crear ramas y commits
- `pull-requests: write` - Comentar en PRs
- `issues: write` - Comentar en issues
- `id-token: write` - Autenticación
- `actions: read` - Leer resultados de CI

---

### `claude-code-review.yml`
Code review automático en cada PR.

**Triggers:**
- PR abierta
- PR actualizada (synchronize)
- PR ready for review
- PR reabierta

**Review enfocado en:**
- Calidad de código
- Bugs potenciales
- Adherencia a estándares de ARC Labs Swift
- Arquitectura, testing, error handling

**Permisos necesarios:**
- `contents: read` - Leer código
- `pull-requests: write` - Comentar review
- `issues: write` - Crear issues si es necesario
- `id-token: write` - Autenticación

---

## 🎯 Repositorios públicos configurados

✅ **15 repositorios:**
1. ARCUIComponents
2. ARCDevTools
3. ARCDesignSystem
4. ARCAuthentication
5. ARCPurchasing
6. ARCKnowledge
7. ARCStorage
8. ARCLinearGitHub-MCP
9. ARCIntelligence
10. ARCFirebase
11. ARCMaps
12. ARCNavigation
13. ARCMetrics
14. ARCNetworking
15. ARCLogger

---

## 🔍 Troubleshooting

### Error: "Environment variable validation failed"
**Causa:** Secret `CLAUDE_CODE_OAUTH_TOKEN` no configurado.
**Solución:** Ejecutar `setup-claude-secret-all-repos.sh`

### Error: "Permission denied"
**Causa:** Permisos insuficientes en workflows.
**Solución:** Ejecutar scripts de fix de permisos.

### Error: "Not Found (404)"
**Causa:** Intentando usar secrets a nivel de organización (requiere Enterprise).
**Solución:** Los scripts configuran secrets a nivel de repositorio.

### Workflow falla pero Claude comenta
**Causa:** Error conocido del SDK después de comentar.
**Estado:** No afecta funcionalidad principal, Claude funciona correctamente.

---

## 📖 Referencias

- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions)
- [Claude Code Action Repo](https://github.com/anthropics/claude-code-action)
- [ARC Labs CLAUDE.md](~/.claude/CLAUDE.md)

---

## 🔄 Actualización

Fecha de última actualización: **2026-01-28**

Estos scripts fueron creados durante la configuración inicial de Claude Code en ARC Labs Studio y están listos para:
- Añadir workflows a nuevos repositorios públicos
- Corregir problemas de permisos en masa
- Reconfigurar secrets cuando sea necesario

---

## 💡 Tips

- **Nuevos repos:** Usa `add-claude-workflows-interactive.sh` para añadir workflows selectivamente
- **Mantenimiento:** Los scripts son idempotentes (detectan si ya están configurados)
- **Ramas protegidas:** Siempre usa la versión `-via-pr.sh` para repos con protección de ramas
- **Backup:** Los scripts clonan temporalmente, nunca modifican tu working directory

---

_Mantenido por ARC Labs Studio_
