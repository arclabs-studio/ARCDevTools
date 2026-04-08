#!/bin/bash
# =============================================================================
# setup-distribution.sh — Create iCloud Distribution folder structure
# =============================================================================
#
# Creates the App Store distribution folder layout in:
#   ~/Documents/ARCLabsStudio/Distribution/
#
# Usage:
#   ./ARCDevTools/scripts/setup-distribution.sh [--app <AppName>]
#   ./ARCDevTools/scripts/setup-distribution.sh --all
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1"; }

# Configuration
DISTRIBUTION_ROOT="$HOME/Documents/ARCLabsStudio/Distribution"
BRANDING_ROOT="$HOME/Documents/ARCLabsStudio/Branding"
ARC_APPS=("FavRes" "FavBook" "PizzeriaLaFamiglia" "TicketMind" "BackHaul")

LOCALES=("en-US" "es-ES")
SCREENSHOT_SIZES=("iPhone-6.9" "iPhone-6.5" "iPad-13")

create_shared_structure() {
    log_info "Creating _shared/ structure..."

    mkdir -p "$DISTRIBUTION_ROOT/_shared/templates"
    mkdir -p "$DISTRIBUTION_ROOT/_shared/press-kit"

    # Create brand symlink if Branding folder exists
    if [ -d "$BRANDING_ROOT" ]; then
        local brand_link="$DISTRIBUTION_ROOT/_shared/brand"
        if [ ! -L "$brand_link" ]; then
            ln -sf "$BRANDING_ROOT" "$brand_link"
            log_success "_shared/brand → $BRANDING_ROOT"
        else
            log_info "_shared/brand → already linked"
        fi
    else
        mkdir -p "$DISTRIBUTION_ROOT/_shared/brand"
        log_warning "Branding folder not found at $BRANDING_ROOT — created empty brand/ instead"
    fi

    log_success "_shared/ structure created"
}

create_app_structure() {
    local app="$1"
    log_info "Creating $app/ structure..."

    # Metadata folders
    for locale in "${LOCALES[@]}"; do
        local metadata_dir="$DISTRIBUTION_ROOT/$app/metadata/$locale"
        mkdir -p "$metadata_dir"

        # Create placeholder files if they don't exist
        for file in name.txt subtitle.txt keywords.txt description.txt release_notes.txt; do
            if [ ! -f "$metadata_dir/$file" ]; then
                touch "$metadata_dir/$file"
            fi
        done
    done

    # Screenshot folders
    for size in "${SCREENSHOT_SIZES[@]}"; do
        mkdir -p "$DISTRIBUTION_ROOT/$app/screenshots/$size"
    done

    # Marketing folders
    mkdir -p "$DISTRIBUTION_ROOT/$app/marketing/social"
    mkdir -p "$DISTRIBUTION_ROOT/$app/marketing/promo"

    log_success "$app/ structure created"
}

create_project_symlinks() {
    local app="$1"

    # Try to find the Xcode project root for this app
    local possible_roots=(
        "$HOME/Developer/ARCLabsStudio/Apps/$app"
        "$HOME/Developer/$app"
        "$HOME/Developer/ARCLabsStudio/$app"
    )

    for app_root in "${possible_roots[@]}"; do
        if [ -d "$app_root" ]; then
            local symlink_path="$app_root/Distribution"
            if [ ! -L "$symlink_path" ] && [ ! -d "$symlink_path" ]; then
                ln -sf "$DISTRIBUTION_ROOT/$app" "$symlink_path"
                log_success "Symlink created: $app_root/Distribution → $DISTRIBUTION_ROOT/$app"
            fi
            return
        fi
    done

    log_info "App project folder not found for $app — skipping symlink"
}

print_structure() {
    echo ""
    echo "Distribution folder structure:"
    echo ""
    echo "$DISTRIBUTION_ROOT/"
    echo "├── _shared/"
    echo "│   ├── templates/"
    echo "│   ├── brand/ → $BRANDING_ROOT"
    echo "│   └── press-kit/"
    for app in "${ARC_APPS[@]}"; do
        echo "├── $app/"
        echo "│   ├── metadata/"
        for locale in "${LOCALES[@]}"; do
            echo "│   │   └── $locale/"
            echo "│   │       ├── name.txt (30 chars max)"
            echo "│   │       ├── subtitle.txt (30 chars max)"
            echo "│   │       ├── keywords.txt (100 chars max)"
            echo "│   │       ├── description.txt (4000 chars max)"
            echo "│   │       └── release_notes.txt"
        done
        echo "│   ├── screenshots/"
        for size in "${SCREENSHOT_SIZES[@]}"; do
            echo "│   │   └── $size/"
        done
        echo "│   └── marketing/"
        echo "│       ├── social/"
        echo "│       └── promo/"
    done
    echo ""
}

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        ARC Labs Distribution Folder Setup                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_info "Distribution root: $DISTRIBUTION_ROOT"

    # Parse arguments
    local target_app=""
    local setup_all=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app)
                target_app="$2"
                shift 2
                ;;
            --all)
                setup_all=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--app <AppName>] [--all]"
                echo ""
                echo "  --app <AppName>  Create structure for specific app"
                echo "  --all            Create structure for all ARC Labs apps (default)"
                echo ""
                echo "Available apps: ${ARC_APPS[*]}"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                exit 1
                ;;
        esac
    done

    # Default to --all if no argument given
    if [ -z "$target_app" ] && [ "$setup_all" = false ]; then
        setup_all=true
    fi

    # Create shared structure
    create_shared_structure

    # Create app structures
    if [ "$setup_all" = true ]; then
        for app in "${ARC_APPS[@]}"; do
            create_app_structure "$app"
            create_project_symlinks "$app"
        done
    elif [ -n "$target_app" ]; then
        create_app_structure "$target_app"
        create_project_symlinks "$target_app"
    fi

    print_structure

    log_success "Distribution setup complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Fill in metadata files in each locale folder"
    echo "  2. Run: arc-distribution validate-metadata --app-id <AppName>"
    echo "  3. Add screenshots to screenshots/ folders"
    echo "  4. Run /arc-aso-audit to score your metadata"
    echo ""
}

main "$@"
