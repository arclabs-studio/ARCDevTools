#!/bin/bash

# ARC Labs Studio - Branch Protection Configuration for All Repositories
# Configures main and develop branches across all public repositories

set -e

ORG="arclabs-studio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛡️  ARC Labs Studio - Branch Protection Configuration${NC}"
echo "================================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed${NC}"
    echo "   Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI${NC}"
    echo "   Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is installed and authenticated${NC}"
echo ""

# Get all active, non-fork public repositories
echo -e "${YELLOW}📋 Fetching repository list...${NC}"
REPOS=$(gh repo list "$ORG" --limit 200 --json name,isArchived,isFork,visibility --jq '.[] | select(.isArchived == false and .isFork == false and .visibility == "public") | .name')

if [ -z "$REPOS" ]; then
    echo -e "${RED}❌ No repositories found${NC}"
    exit 1
fi

REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')
echo -e "${GREEN}✅ Found $REPO_COUNT public repositories${NC}"
echo ""

# Create log file
LOG_FILE="${SCRIPT_DIR}/../logs/branch-protection-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${SCRIPT_DIR}/../logs"

echo "Branch Protection Configuration Log" > "$LOG_FILE"
echo "Started at: $(date)" >> "$LOG_FILE"
echo "=================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

configure_main_branch() {
    local repo=$1

    # Check if main branch exists
    if ! gh api "repos/$ORG/$repo/branches/main" &>/dev/null; then
        echo -e "${YELLOW}    ⚠️  main branch not found, skipping${NC}"
        echo "  ⚠️  $repo: main branch not found" >> "$LOG_FILE"
        return
    fi

    # Configure main branch protection (NO approval requirement for solo work)
    local payload=$(cat <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false,
  "allow_fork_syncing": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false
}
EOF
)

    if echo "$payload" | gh api -X PUT "repos/$ORG/$repo/branches/main/protection" --input - &>/dev/null; then
        echo -e "${GREEN}    ✅ main: protected${NC}"
        echo "  ✅ $repo: main protected" >> "$LOG_FILE"
    else
        echo -e "${RED}    ❌ main: failed${NC}"
        echo "  ❌ $repo: main failed" >> "$LOG_FILE"
    fi
}

configure_develop_branch() {
    local repo=$1

    # Check if develop branch exists
    if ! gh api "repos/$ORG/$repo/branches/develop" &>/dev/null; then
        echo -e "${YELLOW}    ⚠️  develop branch not found, skipping${NC}"
        echo "  ⚠️  $repo: develop branch not found" >> "$LOG_FILE"
        return
    fi

    # Configure develop branch protection (admins can bypass for syncing)
    local payload=$(cat <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": false,
  "allow_fork_syncing": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false
}
EOF
)

    if echo "$payload" | gh api -X PUT "repos/$ORG/$repo/branches/develop/protection" --input - &>/dev/null; then
        echo -e "${GREEN}    ✅ develop: protected (admins can bypass)${NC}"
        echo "  ✅ $repo: develop protected" >> "$LOG_FILE"
    else
        echo -e "${RED}    ❌ develop: failed${NC}"
        echo "  ❌ $repo: develop failed" >> "$LOG_FILE"
    fi
}

# Process each repository
current=0
while IFS= read -r repo; do
    current=$((current + 1))
    echo -e "${BLUE}[$current/$REPO_COUNT]${NC} Processing: ${YELLOW}$repo${NC}"
    echo "" >> "$LOG_FILE"
    echo "[$current/$REPO_COUNT] $repo" >> "$LOG_FILE"

    configure_main_branch "$repo"
    configure_develop_branch "$repo"

    echo ""
done <<< "$REPOS"

echo "=================================================" >> "$LOG_FILE"
echo "Completed at: $(date)" >> "$LOG_FILE"

echo -e "${GREEN}✅ Configuration complete!${NC}"
echo ""
echo -e "${BLUE}📝 Summary:${NC}"
echo -e "  ${YELLOW}main:${NC} No deletion, no force push, enforce for admins, no approvals required"
echo -e "  ${YELLOW}develop:${NC} No deletion, no force push, admins can bypass (for syncing)"
echo ""
echo -e "${BLUE}📄 Log file:${NC} $LOG_FILE"
echo ""
echo -e "${BLUE}ℹ️  Note:${NC} Private repositories require GitHub Pro for branch protection."
echo -e "   This script only configures public repositories."
