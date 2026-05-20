#!/bin/bash
# =============================================================================
# arc-memory-prune.sh - Audit Claude Code auto-memory directories
# =============================================================================
#
# Scans ~/.claude/projects/*/memory/ across every project that Claude Code has
# tracked on this machine and reports stale entries (default: not modified in
# more than 60 days). Read-only by default; pass --delete to actually remove
# files (with per-file confirmation unless --yes is also given).
#
# Cross-machine safe: walks $HOME/.claude/projects, never the current user's
# absolute path. Safe to run on any developer machine — it only touches that
# user's own ~/.claude tree.
#
# Usage:
#   ./ARCDevTools/scripts/arc-memory-prune.sh                    # report only
#   ./ARCDevTools/scripts/arc-memory-prune.sh --days 90          # custom threshold
#   ./ARCDevTools/scripts/arc-memory-prune.sh --delete           # interactive prune
#   ./ARCDevTools/scripts/arc-memory-prune.sh --delete --yes     # non-interactive
#   ./ARCDevTools/scripts/arc-memory-prune.sh --root /custom     # alternate root
#
# Exit codes:
#   0 — completed successfully (even if stale files were found in report mode)
#   1 — argument or environment error
#   2 — user aborted a deletion prompt
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
    C_BOLD="$(tput bold)"
    C_RESET="$(tput sgr0)"
else
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_DIM=""; C_BOLD=""; C_RESET=""
fi

log_info()    { echo "${C_BLUE}i${C_RESET} $*"; }
log_success() { echo "${C_GREEN}OK${C_RESET} $*"; }
log_warn()    { echo "${C_YELLOW}!!${C_RESET} $*"; }
log_error()   { echo "${C_RED}xx${C_RESET} $*" >&2; }

# -----------------------------------------------------------------------------
# Defaults & argument parsing
# -----------------------------------------------------------------------------
DAYS=60
WARN_DAYS=30
ROOT="$HOME/.claude/projects"
DO_DELETE=0
ASSUME_YES=0
VERBOSE=0

usage() {
    cat <<USAGE
Usage: $(basename "$0") [options]

Audit Claude Code auto-memory directories for stale entries.

Options:
  --days <N>     Stale threshold in days (default: $DAYS)
  --warn <N>     Warning threshold in days (default: $WARN_DAYS, yellow)
  --root <path>  Override scan root (default: \$HOME/.claude/projects)
  --delete       Delete stale files (prompts unless --yes)
  --yes          Skip confirmation prompts (use with --delete)
  --verbose      Show all files, not just stale ones
  -h, --help     Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --days 90
  $(basename "$0") --delete
  $(basename "$0") --delete --yes --days 120
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --days)    DAYS="${2:?--days requires a number}"; shift 2 ;;
        --warn)    WARN_DAYS="${2:?--warn requires a number}"; shift 2 ;;
        --root)    ROOT="${2:?--root requires a path}"; shift 2 ;;
        --delete)  DO_DELETE=1; shift ;;
        --yes)     ASSUME_YES=1; shift ;;
        --verbose) VERBOSE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *)         log_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || ! [[ "$WARN_DAYS" =~ ^[0-9]+$ ]]; then
    log_error "--days and --warn must be non-negative integers"
    exit 1
fi

if [[ ! -d "$ROOT" ]]; then
    log_error "scan root does not exist: $ROOT"
    log_info "Claude Code may not have been used on this machine yet."
    exit 1
fi

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
# File mtime in seconds since epoch (BSD vs GNU stat compatibility)
file_mtime() {
    if stat -f%m "$1" >/dev/null 2>&1; then
        stat -f%m "$1"
    else
        stat -c%Y "$1"
    fi
}

# Human-readable file size
file_size_human() {
    if command -v du >/dev/null 2>&1; then
        du -h "$1" 2>/dev/null | awk '{print $1}'
    else
        echo "?"
    fi
}

# Parse `name:` and `description:` from frontmatter (YAML between leading ---)
parse_frontmatter() {
    local file="$1"
    local field="$2"
    awk -v field="$field" '
        BEGIN { in_fm=0; lines=0 }
        /^---[[:space:]]*$/ {
            if (in_fm) { exit } else { in_fm=1; next }
        }
        in_fm {
            lines++
            if (lines > 200) exit
            # Match "field: value" with optional surrounding whitespace
            if (match($0, "^[[:space:]]*" field "[[:space:]]*:[[:space:]]*")) {
                val = substr($0, RSTART + RLENGTH)
                # Strip surrounding quotes
                gsub(/^["'"'"']|["'"'"']$/, "", val)
                print val
                exit
            }
        }
    ' "$file"
}

age_days() {
    local mtime="$1"
    local now="$2"
    echo $(( (now - mtime) / 86400 ))
}

color_for_age() {
    local age="$1"
    if   [[ "$age" -ge "$DAYS" ]];      then printf '%s' "$C_RED"
    elif [[ "$age" -ge "$WARN_DAYS" ]]; then printf '%s' "$C_YELLOW"
    else                                     printf '%s' "$C_GREEN"
    fi
}

confirm() {
    local prompt="$1"
    [[ $ASSUME_YES -eq 1 ]] && return 0
    read -r -p "$prompt [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------
NOW="$(date +%s)"

echo
echo "================================================================"
echo " ${C_BOLD}Claude Memory Audit${C_RESET}"
echo "================================================================"
log_info "scan root:    $ROOT"
log_info "stale after:  $DAYS days  ${C_DIM}(warn at $WARN_DAYS)${C_RESET}"
[[ $DO_DELETE -eq 1 ]] && log_warn "DELETE mode  ${C_DIM}(--yes=$ASSUME_YES)${C_RESET}"
echo

# -----------------------------------------------------------------------------
# Scan
# -----------------------------------------------------------------------------
TOTAL_FILES=0
TOTAL_STALE=0
TOTAL_DELETED=0
TOTAL_PROJECTS=0
TOTAL_BYTES=0

# Iterate ~/.claude/projects/*/memory/
shopt -s nullglob
for project_dir in "$ROOT"/*/; do
    # Strip trailing slash from project_dir for cleaner output
    project_dir="${project_dir%/}"
    memory_dir="$project_dir/memory"
    [[ -d "$memory_dir" ]] || continue

    # Project name: encoded form is /-Users-foo-bar-MyApp — use the last
    # hyphen-segment as a friendly name when possible.
    encoded="$(basename "$project_dir")"
    friendly="${encoded##*-}"
    [[ -z "$friendly" ]] && friendly="$encoded"

    project_files=0
    project_stale=0
    project_oldest=0
    project_bytes=0

    # Collect files into array (handle no-match)
    files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$memory_dir" -type f -print0 2>/dev/null)

    [[ ${#files[@]} -eq 0 ]] && continue

    ((TOTAL_PROJECTS++)) || true
    echo "${C_BOLD}# $friendly${C_RESET}  ${C_DIM}($memory_dir)${C_RESET}"

    # Sort by mtime ascending (oldest first)
    if [[ ${#files[@]} -gt 1 ]]; then
        # shellcheck disable=SC2207
        sorted=($(for f in "${files[@]}"; do
            printf '%s\t%s\n' "$(file_mtime "$f")" "$f"
        done | sort -n | cut -f2-))
        files=("${sorted[@]}")
    fi

    for file in "${files[@]}"; do
        mtime="$(file_mtime "$file")"
        age="$(age_days "$mtime" "$NOW")"
        size_bytes=0
        if size_bytes_raw=$(wc -c <"$file" 2>/dev/null); then
            size_bytes="${size_bytes_raw// /}"
        fi
        size_human="$(file_size_human "$file")"
        rel="${file#$memory_dir/}"

        ((project_files++)) || true
        ((TOTAL_FILES++)) || true
        project_bytes=$((project_bytes + size_bytes))
        TOTAL_BYTES=$((TOTAL_BYTES + size_bytes))
        [[ "$age" -gt "$project_oldest" ]] && project_oldest=$age

        is_stale=0
        [[ "$age" -ge "$DAYS" ]] && is_stale=1

        if [[ "$is_stale" -eq 1 ]]; then
            ((project_stale++)) || true
            ((TOTAL_STALE++)) || true
        fi

        # Skip non-stale unless verbose
        if [[ "$is_stale" -eq 0 ]] && [[ $VERBOSE -eq 0 ]]; then
            continue
        fi

        color="$(color_for_age "$age")"
        name_field="$(parse_frontmatter "$file" "name" 2>/dev/null || true)"
        desc_field="$(parse_frontmatter "$file" "description" 2>/dev/null || true)"
        meta=""
        [[ -n "$name_field" ]] && meta=" ${C_DIM}name=${C_RESET}${name_field}"
        if [[ -n "$desc_field" ]]; then
            # Truncate long descriptions
            short="${desc_field:0:70}"
            [[ "${#desc_field}" -gt 70 ]] && short="${short}..."
            meta="${meta} ${C_DIM}desc=${C_RESET}${short}"
        fi

        printf '  %s%4dd%s  %6s  %s%s\n' \
            "$color" "$age" "$C_RESET" "$size_human" "$rel" "$meta"

        if [[ "$is_stale" -eq 1 ]] && [[ $DO_DELETE -eq 1 ]]; then
            if confirm "    delete $rel?"; then
                rm -f "$file"
                log_success "    deleted"
                ((TOTAL_DELETED++)) || true
            else
                log_info "    skipped"
            fi
        fi
    done

    # Project summary
    printf "  %s---%s files=%d stale=%d oldest=%dd size=%s\n\n" \
        "$C_DIM" "$C_RESET" \
        "$project_files" "$project_stale" "$project_oldest" \
        "$(numfmt --to=iec --suffix=B "$project_bytes" 2>/dev/null || echo "${project_bytes}B")"
done
shopt -u nullglob

# -----------------------------------------------------------------------------
# Totals
# -----------------------------------------------------------------------------
echo "================================================================"
echo " ${C_BOLD}Summary${C_RESET}"
echo "================================================================"
log_info "projects scanned: $TOTAL_PROJECTS"
log_info "files total:      $TOTAL_FILES"
if [[ "$TOTAL_STALE" -gt 0 ]]; then
    log_warn "stale (>= ${DAYS}d): $TOTAL_STALE"
else
    log_success "stale (>= ${DAYS}d): 0"
fi
log_info "total size:       $(numfmt --to=iec --suffix=B "$TOTAL_BYTES" 2>/dev/null || echo "${TOTAL_BYTES}B")"
[[ $DO_DELETE -eq 1 ]] && log_info "deleted:          $TOTAL_DELETED"

if [[ $DO_DELETE -eq 0 ]] && [[ "$TOTAL_STALE" -gt 0 ]]; then
    echo
    log_info "re-run with --delete to prune (per-file confirmation)"
    log_info "or --delete --yes for non-interactive cleanup"
fi

echo
log_success "done"
