#!/bin/bash
# =============================================================================
# arc-setup-notes-system.sh - Bootstrap the ARC notes/Obsidian system in a repo
# =============================================================================
#
# Idempotent setup of the .claude/hooks/ scaffold used by every ARC project to
# bridge the repository with its Obsidian vault folder. Run from inside the
# target repo (or pass --root). Writes:
#
#   .claude/hooks/setup-notes.sh   (creates the `notes` symlink)
#   .claude/hooks/sync-plans.sh    (Stop hook — archives Claude plans)
#   .gitignore                     (appends `notes` if missing)
#
# Cross-machine safe: hooks resolve $HOME at runtime, never the current user.
#
# Usage:
#   ./ARCDevTools/scripts/arc-setup-notes-system.sh
#   ./ARCDevTools/scripts/arc-setup-notes-system.sh --name FavRes
#   ./ARCDevTools/scripts/arc-setup-notes-system.sh --root /path/to/repo --dry-run
#   ./ARCDevTools/scripts/arc-setup-notes-system.sh --verbose
#
# Project name detection:
#   1. --name <ProjectName> if provided
#   2. basename of git toplevel, with -iOS / -Android / -Web suffix stripped
#
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Color output (TTY-aware)
# -----------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
    C_RED="$(tput setaf 1)"
    C_GREEN="$(tput setaf 2)"
    C_YELLOW="$(tput setaf 3)"
    C_BLUE="$(tput setaf 4)"
    C_DIM="$(tput dim)"
    C_RESET="$(tput sgr0)"
else
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_DIM=""; C_RESET=""
fi

log_info()    { echo "${C_BLUE}i${C_RESET} $*"; }
log_success() { echo "${C_GREEN}OK${C_RESET} $*"; }
log_warn()    { echo "${C_YELLOW}!!${C_RESET} $*"; }
log_error()   { echo "${C_RED}xx${C_RESET} $*" >&2; }
log_debug()   { [[ "${VERBOSE:-0}" == "1" ]] && echo "${C_DIM}.. $*${C_RESET}" || true; }

# -----------------------------------------------------------------------------
# Defaults & argument parsing
# -----------------------------------------------------------------------------
PROJECT_NAME=""
REPO_ROOT=""
DRY_RUN=0
VERBOSE=0

usage() {
    cat <<USAGE
Usage: $(basename "$0") [options]

Bootstrap the ARC notes/Obsidian system in the current repository.

Options:
  --name <ProjectName>   Override detected project name (default: git-derived)
  --root <path>          Repository root (default: current git toplevel)
  --dry-run              Show what would be done without writing anything
  --verbose              Verbose logging
  -h, --help             Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --name FavRes
  $(basename "$0") --root ~/Developer/Apps/FavRes-iOS --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)     PROJECT_NAME="${2:?--name requires a value}"; shift 2 ;;
        --root)     REPO_ROOT="${2:?--root requires a value}"; shift 2 ;;
        --dry-run)  DRY_RUN=1; shift ;;
        --verbose)  VERBOSE=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *)          log_error "Unknown argument: $1"; usage; exit 2 ;;
    esac
done

# -----------------------------------------------------------------------------
# Resolve repo root and project name
# -----------------------------------------------------------------------------
if [[ -z "$REPO_ROOT" ]]; then
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

if [[ ! -d "$REPO_ROOT" ]]; then
    log_error "Repo root does not exist: $REPO_ROOT"
    exit 1
fi

if [[ -z "$PROJECT_NAME" ]]; then
    raw_name="$(basename "$REPO_ROOT")"
    # Strip platform suffix: FavRes-iOS -> FavRes, MyApp-Android -> MyApp
    PROJECT_NAME="${raw_name%-iOS}"
    PROJECT_NAME="${PROJECT_NAME%-Android}"
    PROJECT_NAME="${PROJECT_NAME%-Web}"
    PROJECT_NAME="${PROJECT_NAME%-macOS}"
fi

VAULT_PATH="$HOME/Documents/ObsidianVault/01 - Projects/$PROJECT_NAME"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"
GITIGNORE="$REPO_ROOT/.gitignore"

echo
echo "================================================================"
echo " ARC Notes System Bootstrap"
echo "================================================================"
log_info "Repo root:    $REPO_ROOT"
log_info "Project name: $PROJECT_NAME"
log_info "Vault path:   $VAULT_PATH"
[[ $DRY_RUN -eq 1 ]] && log_warn "DRY RUN — no files will be written"
echo

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
# Render setup-notes.sh into a target path, parameterized by PROJECT_NAME.
# Uses a quoted heredoc (no expansion) plus a sed substitution for the one
# template variable — avoids quoting hell with $(...) and single quotes inside
# the script body.
render_setup_notes() {
    local out="$1"
    local name="$2"
    cat > "$out" <<'TEMPLATE'
#!/bin/bash
# ARC Labs Studio - setup-notes.sh
# Idempotent. Creates `notes/` symlink to Obsidian vault.
# Cross-machine: uses $HOME, not hardcoded user.
# Requires vault at $HOME/Documents/ObsidianVault/01 - Projects/__ARC_PROJECT_NAME__
set -e
PROJECT_NAME="__ARC_PROJECT_NAME__"
VAULT_PATH="$HOME/Documents/ObsidianVault/01 - Projects/$PROJECT_NAME"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
if [ -L "notes" ]; then exit 0; fi
if [ -e "notes" ] && [ ! -L "notes" ]; then
  echo "[setup-notes] WARN: 'notes' exists and is not a symlink - skipping"
  exit 0
fi
if [ ! -d "$VAULT_PATH" ]; then
  echo "[setup-notes] vault not found at $VAULT_PATH - skipping (notes integration disabled on this machine)"
  exit 0
fi
ln -s "$VAULT_PATH" notes
echo "[setup-notes] linked notes -> $VAULT_PATH"
TEMPLATE
    # Substitute project name placeholder (use | as delimiter to allow / etc.)
    # Use a portable in-place edit (BSD sed needs '' after -i)
    if sed --version >/dev/null 2>&1; then
        sed -i "s|__ARC_PROJECT_NAME__|${name}|g" "$out"
    else
        sed -i '' "s|__ARC_PROJECT_NAME__|${name}|g" "$out"
    fi
}

render_sync_plans() {
    local out="$1"
    cat > "$out" <<'TEMPLATE'
#!/bin/bash
# ARC Labs Studio - sync-plans.sh (Stop hook)
# Copies recently-modified Claude plans into notes/plans/ for archival.
# Idempotent. Skips silently if notes/plans/ doesn't exist (un-symlinked checkout).
set -e
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PLANS_DIR="$REPO_ROOT/notes/plans"
SOURCE_DIR="$HOME/.claude/plans"
[ -d "$PLANS_DIR" ] || exit 0
[ -d "$SOURCE_DIR" ] || exit 0
BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
# Strip type prefix: feature/FVRS-222-foo -> FVRS-222-foo
BRANCH_SLUG="${BRANCH##*/}"
DATE="$(date +%Y-%m-%d)"
# Find plans modified in last 8 hours
find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.md" -mmin -480 2>/dev/null | while read -r plan; do
  STEM="$(basename "$plan" .md)"
  TARGET="$PLANS_DIR/${DATE}-${BRANCH_SLUG}-${STEM}.md"
  [ -f "$TARGET" ] && continue   # idempotent
  cp "$plan" "$TARGET" 2>/dev/null && echo "[sync-plans] copied $STEM -> notes/plans/"
done
exit 0
TEMPLATE
}

# Render to a temp file and compare; only overwrite if different.
maybe_install() {
    local target="$1"
    local renderer="$2"   # function name
    local arg2="${3:-}"   # optional second arg passed to renderer
    local label="${target#$REPO_ROOT/}"

    local tmp
    tmp="$(mktemp)"
    if [[ -n "$arg2" ]]; then
        "$renderer" "$tmp" "$arg2"
    else
        "$renderer" "$tmp"
    fi

    if [[ -f "$target" ]] && cmp -s "$tmp" "$target"; then
        rm -f "$tmp"
        log_info "up-to-date: $label"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        rm -f "$tmp"
        log_info "would write: $label"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    mv "$tmp" "$target"
    chmod 0755 "$target"
    log_success "wrote: $label"
}

# -----------------------------------------------------------------------------
# Step 1: Write hooks
# -----------------------------------------------------------------------------
log_info "Step 1/3 - Hooks"

setup_path="$HOOKS_DIR/setup-notes.sh"
sync_path="$HOOKS_DIR/sync-plans.sh"

maybe_install "$setup_path" render_setup_notes "$PROJECT_NAME"
maybe_install "$sync_path"  render_sync_plans

# -----------------------------------------------------------------------------
# Step 2: .gitignore
# -----------------------------------------------------------------------------
echo
log_info "Step 2/3 — .gitignore"

if [[ -f "$GITIGNORE" ]] && grep -qxE '^notes/?$' "$GITIGNORE"; then
    log_info "already ignored: notes"
else
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "would append 'notes' to .gitignore"
    else
        # Ensure trailing newline before appending
        if [[ -f "$GITIGNORE" ]] && [[ -n "$(tail -c1 "$GITIGNORE" 2>/dev/null)" ]]; then
            printf '\n' >> "$GITIGNORE"
        fi
        printf '\n# ARC notes system (Obsidian symlink)\nnotes\n' >> "$GITIGNORE"
        log_success "appended 'notes' to .gitignore"
    fi
fi

# -----------------------------------------------------------------------------
# Step 3: Try to run setup-notes.sh if vault exists
# -----------------------------------------------------------------------------
echo
log_info "Step 3/3 — Vault detection"

if [[ -d "$VAULT_PATH" ]]; then
    log_success "vault found at: $VAULT_PATH"
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "would run setup-notes.sh to create the symlink"
    else
        if bash "$setup_path"; then
            log_success "ran setup-notes.sh"
        else
            log_warn "setup-notes.sh exited non-zero — check above"
        fi
    fi
else
    log_warn "vault NOT found at: $VAULT_PATH"
    log_info "create the folder in Obsidian, then re-run: bash .claude/hooks/setup-notes.sh"
fi

# -----------------------------------------------------------------------------
# Next steps
# -----------------------------------------------------------------------------
echo
echo "================================================================"
echo " Next steps"
echo "================================================================"
cat <<NEXT

1. Wire the hooks into .claude/settings.local.json:

   {
     "hooks": {
       "SessionStart": [
         { "hooks": [ { "type": "command",
                        "command": ".claude/hooks/setup-notes.sh" } ] }
       ],
       "Stop": [
         { "hooks": [ { "type": "command",
                        "command": ".claude/hooks/sync-plans.sh" } ] }
       ]
     },
     "permissions": {
       "allow": [ "Write(./notes/**)" ]
     }
   }

2. Add the "Notes & Obsidian" section to your CLAUDE.md (see the FavRes-iOS
   CLAUDE.md for the canonical version — explains folder conventions,
   troubleshooting note format, and plan auto-sync behavior).

3. Each new clone or worktree must re-run setup-notes.sh (the symlink is
   gitignored). The SessionStart hook handles this automatically.

NEXT

[[ $DRY_RUN -eq 1 ]] && log_warn "dry-run complete — nothing was written"
log_success "done"
