#!/usr/bin/env bash

# Script to fix Claude workflow permissions in all public ARC Labs repositories
# Updates claude.yml to have write permissions for issues and pull-requests

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ORG="arclabs-studio"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Fix Claude Workflow Permissions${NC}"
echo -e "${BLUE}================================================${NC}\n"

echo -e "${BLUE}📋 Fetching public repositories...${NC}\n"

# Get list of public repositories (excluding ARCUIComponents which is already fixed)
PUBLIC_REPOS=$(gh repo list "$ORG" --limit 100 --json name,isPrivate --jq '.[] | select(.isPrivate == false and .name != "ARCUIComponents") | .name')

if [[ -z "$PUBLIC_REPOS" ]]; then
    echo -e "${RED}❌ No public repositories found${NC}"
    exit 1
fi

# Convert to array
REPO_ARRAY=()
while IFS= read -r line; do
    REPO_ARRAY+=("$line")
done <<< "$PUBLIC_REPOS"
REPO_COUNT=${#REPO_ARRAY[@]}

echo -e "${GREEN}✅ Found $REPO_COUNT repositories to update${NC}\n"

# Counter for processed repos
SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# Process each repository
for REPO in "${REPO_ARRAY[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Processing: ${YELLOW}$REPO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    REPO_DIR="$TEMP_DIR/$REPO"

    # Clone repository
    echo -e "  ${BLUE}↓${NC} Cloning repository..."
    if ! git clone "https://github.com/$ORG/$REPO.git" "$REPO_DIR" --quiet 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone $REPO${NC}\n"
        ((ERROR_COUNT++))
        continue
    fi

    cd "$REPO_DIR"

    # Get default branch
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null || echo "main")
    git checkout "$DEFAULT_BRANCH" --quiet 2>/dev/null || { echo -e "  ${RED}❌ Failed to checkout $DEFAULT_BRANCH${NC}\n"; ((ERROR_COUNT++)); cd - > /dev/null; continue; }

    # Check if claude.yml exists
    if [[ ! -f ".github/workflows/claude.yml" ]]; then
        echo -e "  ${YELLOW}⊘ claude.yml doesn't exist - skipping${NC}\n"
        ((SKIP_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Check if permissions are already correct
    if grep -q "pull-requests: write" ".github/workflows/claude.yml" && grep -q "issues: write" ".github/workflows/claude.yml"; then
        echo -e "  ${YELLOW}⊘ Permissions already correct - skipping${NC}\n"
        ((SKIP_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Create new branch
    BRANCH_NAME="fix/claude-workflow-permissions-$(date +%s)"
    echo -e "  ${BLUE}🌿${NC} Creating branch: $BRANCH_NAME..."
    git checkout -b "$BRANCH_NAME" --quiet

    # Update permissions in claude.yml
    echo -e "  ${BLUE}📝${NC} Updating permissions in claude.yml..."
    sed -i.bak 's/pull-requests: read/pull-requests: write/' .github/workflows/claude.yml
    sed -i.bak 's/issues: read/issues: write/' .github/workflows/claude.yml
    rm .github/workflows/claude.yml.bak 2>/dev/null || true

    # Stage changes
    git add .github/workflows/claude.yml

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo -e "  ${YELLOW}⊘ No changes to commit - skipping${NC}\n"
        ((SKIP_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Commit changes
    echo -e "  ${BLUE}✓${NC} Committing changes..."
    git commit -m "fix(ci): update Claude workflow permissions to write

- Change pull-requests: read -> write (required to comment on PRs)
- Change issues: read -> write (required to comment on issues)
- Fixes \"Environment variable validation failed\" error" --quiet

    # Push branch
    echo -e "  ${BLUE}↑${NC} Pushing branch to origin..."
    if ! git push origin "$BRANCH_NAME" --quiet 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to push branch to $REPO${NC}\n"
        ((ERROR_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Create Pull Request
    echo -e "  ${BLUE}📝${NC} Creating Pull Request..."
    PR_URL=$(gh pr create \
        --repo "$ORG/$REPO" \
        --base "$DEFAULT_BRANCH" \
        --head "$BRANCH_NAME" \
        --title "fix(ci): update Claude workflow permissions" \
        --body "## Problem

The Claude Code workflow needs write permissions to comment on issues and PRs.

## Solution

Update permissions in \`.github/workflows/claude.yml\`:
- ✅ \`pull-requests: write\` (was: read)
- ✅ \`issues: write\` (was: read)

## After merge

- ✅ \`@claude\` mentions will work in all issues/PRs
- ✅ Claude can respond to questions and help with development

## Related

- Fixed in ARCUIComponents: https://github.com/arclabs-studio/ARCUIComponents/pull/45" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✅ Pull Request created successfully${NC}"
        echo -e "  ${BLUE}🔗 $PR_URL${NC}\n"
        ((SUCCESS_COUNT++))
    else
        echo -e "  ${RED}❌ Failed to create PR for $REPO${NC}\n"
        ((ERROR_COUNT++))
    fi

    # Go back to temp directory
    cd - > /dev/null

done

# Cleanup
echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

# Summary
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ Pull Requests created: $SUCCESS_COUNT${NC}"
echo -e "${YELLOW}⊘  Skipped (already correct): $SKIP_COUNT${NC}"
echo -e "${RED}❌ Errors: $ERROR_COUNT${NC}"
echo -e "${BLUE}📊 Total repositories: $REPO_COUNT${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 Pull Requests have been created!${NC}"
    echo -e "${GREEN}   Review and merge them to enable Claude workflows.${NC}\n"
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some repositories had errors. Please check manually.${NC}\n"
    exit 1
fi
