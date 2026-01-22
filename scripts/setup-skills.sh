#!/bin/bash
# =============================================================================
# setup-skills.sh - Setup ARCKnowledge skills for Claude Code
# =============================================================================
#
# This script creates symlinks from .claude/skills/ to ARCKnowledge skills,
# making them accessible from the project root.
#
# Usage:
#   ./ARCDevTools/scripts/setup-skills.sh
#   ./scripts/setup-skills.sh (from ARCDevTools directory)
#
# Why this is needed:
#   Claude Code only discovers skills in .claude/skills/ at the project root.
#   Skills in subdirectories (like submodules) are not automatically accessible.
#   This script creates symlinks to maintain a single source of truth while
#   making skills available at the project level.
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Find project root (look for Package.swift or .git)
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/Package.swift" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

# Find ARCKnowledge directory
find_arcknowledge() {
    local project_root="$1"
    local possible_paths=(
        # Direct submodule
        "$project_root/ARCKnowledge"
        # Inside ARCDevTools submodule
        "$project_root/ARCDevTools/ARCKnowledge"
        # Inside nested path
        "$project_root/Submodules/ARCDevTools/ARCKnowledge"
        "$project_root/Dependencies/ARCDevTools/ARCKnowledge"
        # SPM checkouts (less ideal but possible)
        "$project_root/.build/checkouts/ARCDevTools/ARCKnowledge"
    )

    for path in "${possible_paths[@]}"; do
        if [[ -d "$path/.claude/skills" ]]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Get relative path from source to target
relative_path() {
    local source="$1"
    local target="$2"
    python3 -c "import os.path; print(os.path.relpath('$target', '$source'))"
}

# Main function
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           ARCKnowledge Skills Setup for Claude Code            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Find project root
    PROJECT_ROOT=$(find_project_root)
    log_info "Project root: $PROJECT_ROOT"

    # Find ARCKnowledge
    ARCKNOWLEDGE_PATH=$(find_arcknowledge "$PROJECT_ROOT") || {
        log_error "Could not find ARCKnowledge directory"
        log_info "Expected locations:"
        log_info "  - $PROJECT_ROOT/ARCKnowledge"
        log_info "  - $PROJECT_ROOT/ARCDevTools/ARCKnowledge"
        echo ""
        log_info "Make sure ARCDevTools is properly set up as a submodule:"
        log_info "  git submodule add https://github.com/arclabs-studio/ARCDevTools.git ARCDevTools"
        log_info "  git submodule update --init --recursive"
        exit 1
    }
    log_success "Found ARCKnowledge: $ARCKNOWLEDGE_PATH"

    # Source skills directory
    SKILLS_SOURCE="$ARCKNOWLEDGE_PATH/.claude/skills"
    if [[ ! -d "$SKILLS_SOURCE" ]]; then
        log_error "Skills directory not found: $SKILLS_SOURCE"
        exit 1
    fi

    # Target directory
    SKILLS_TARGET="$PROJECT_ROOT/.claude/skills"

    # Create .claude/skills directory if it doesn't exist
    if [[ ! -d "$SKILLS_TARGET" ]]; then
        log_info "Creating $SKILLS_TARGET"
        mkdir -p "$SKILLS_TARGET"
    fi

    # Count skills
    local skills_linked=0
    local skills_skipped=0
    local skills_updated=0

    echo ""
    log_info "Linking skills..."
    echo ""

    # Create symlinks for each skill
    for skill_dir in "$SKILLS_SOURCE"/*/; do
        if [[ -d "$skill_dir" ]]; then
            skill_name=$(basename "$skill_dir")
            target_link="$SKILLS_TARGET/$skill_name"

            # Calculate relative path for symlink
            rel_path=$(relative_path "$SKILLS_TARGET" "$skill_dir")
            # Remove trailing slash
            rel_path="${rel_path%/}"

            if [[ -L "$target_link" ]]; then
                # Symlink exists, check if it points to the right place
                current_target=$(readlink "$target_link")
                if [[ "$current_target" == "$rel_path" ]]; then
                    log_info "  $skill_name → already linked"
                    ((skills_skipped++))
                else
                    # Update symlink
                    rm "$target_link"
                    ln -s "$rel_path" "$target_link"
                    log_success "  $skill_name → updated"
                    ((skills_updated++))
                fi
            elif [[ -e "$target_link" ]]; then
                # Something exists but it's not a symlink
                log_warning "  $skill_name → skipped (file/directory exists)"
                ((skills_skipped++))
            else
                # Create new symlink
                ln -s "$rel_path" "$target_link"
                log_success "  $skill_name → linked"
                ((skills_linked++))
            fi
        fi
    done

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    log_success "Skills setup complete!"
    echo ""
    echo "  New links:     $skills_linked"
    echo "  Updated:       $skills_updated"
    echo "  Skipped:       $skills_skipped"
    echo ""

    # Verify skills are accessible
    echo "Linked skills:"
    for skill_link in "$SKILLS_TARGET"/*/; do
        if [[ -d "$skill_link" ]]; then
            skill_name=$(basename "$skill_link")
            if [[ -f "$skill_link/SKILL.md" ]]; then
                echo "  ✓ $skill_name"
            fi
        fi
    done

    echo ""
    log_info "Skills are now available in Claude Code via /skill-name"
    echo ""

    # Git ignore recommendation
    if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
        if ! grep -q ".claude/skills" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
            echo ""
            log_warning "Consider adding symlinked skills to .gitignore:"
            echo ""
            echo "  # ARCKnowledge skills (symlinks)"
            echo "  .claude/skills/arc-*"
            echo ""
        fi
    fi
}

# Run main
main "$@"
