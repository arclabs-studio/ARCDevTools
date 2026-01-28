#!/usr/bin/env bash

# Script to add Claude workflows to all public ARC Labs repositories
# Usage: ./add-claude-workflows.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ORG="arclabs-studio"
WORKFLOW_DIR=".github/workflows"
TEMP_DIR=$(mktemp -d)
SOURCE_WORKFLOWS_DIR="$(pwd)/.github/workflows"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Adding Claude Workflows to Public Repos${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Check if workflow files exist
if [[ ! -f "$SOURCE_WORKFLOWS_DIR/claude.yml" ]] || [[ ! -f "$SOURCE_WORKFLOWS_DIR/claude-code-review.yml" ]]; then
    echo -e "${RED}❌ Error: Workflow files not found in $SOURCE_WORKFLOWS_DIR${NC}"
    echo -e "${RED}   Please run this script from the FavRes-iOS directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Fetching public repositories...${NC}\n"

# Get list of public repositories
PUBLIC_REPOS=$(gh repo list "$ORG" --limit 100 --json name,isPrivate,visibility --jq '.[] | select(.isPrivate == false) | .name')

if [[ -z "$PUBLIC_REPOS" ]]; then
    echo -e "${RED}❌ No public repositories found${NC}"
    exit 1
fi

# Count repos
REPO_COUNT=$(echo "$PUBLIC_REPOS" | wc -l | tr -d ' ')
echo -e "${GREEN}✅ Found $REPO_COUNT public repositories${NC}\n"

# Counter for processed repos
SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# Process each repository
while IFS= read -r REPO; do
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
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
    git checkout "$DEFAULT_BRANCH" --quiet 2>/dev/null || git checkout main --quiet 2>/dev/null || git checkout master --quiet 2>/dev/null

    # Check if workflows already exist
    if [[ -f "$WORKFLOW_DIR/claude.yml" ]] && [[ -f "$WORKFLOW_DIR/claude-code-review.yml" ]]; then
        echo -e "  ${YELLOW}⊘ Workflows already exist - skipping${NC}\n"
        ((SKIP_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Create workflows directory if it doesn't exist
    mkdir -p "$WORKFLOW_DIR"

    # Copy workflow files
    echo -e "  ${BLUE}📄${NC} Copying claude.yml..."
    cp "$SOURCE_WORKFLOWS_DIR/claude.yml" "$WORKFLOW_DIR/claude.yml"

    echo -e "  ${BLUE}📄${NC} Copying claude-code-review.yml..."
    cp "$SOURCE_WORKFLOWS_DIR/claude-code-review.yml" "$WORKFLOW_DIR/claude-code-review.yml"

    # Stage changes
    git add "$WORKFLOW_DIR/"

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo -e "  ${YELLOW}⊘ No changes to commit - skipping${NC}\n"
        ((SKIP_COUNT++))
        cd - > /dev/null
        continue
    fi

    # Commit changes
    echo -e "  ${BLUE}✓${NC} Committing changes..."
    git commit -m "chore(ci): add Claude GitHub Actions workflows

- Add claude.yml: Respond to @claude mentions in issues/PRs
- Add claude-code-review.yml: Automated PR code reviews
- Follows ARC Labs Swift standards
- Configured with CLAUDE_CODE_OAUTH_TOKEN secret" --quiet

    # Push changes
    echo -e "  ${BLUE}↑${NC} Pushing to $DEFAULT_BRANCH..."
    if git push origin "$DEFAULT_BRANCH" --quiet 2>/dev/null; then
        echo -e "  ${GREEN}✅ Successfully added workflows to $REPO${NC}\n"
        ((SUCCESS_COUNT++))
    else
        echo -e "  ${RED}❌ Failed to push changes to $REPO${NC}\n"
        ((ERROR_COUNT++))
    fi

    # Go back to temp directory
    cd - > /dev/null

done <<< "$PUBLIC_REPOS"

# Cleanup
echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"

# Summary
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ Successfully processed: $SUCCESS_COUNT${NC}"
echo -e "${YELLOW}⊘  Skipped (already exist): $SKIP_COUNT${NC}"
echo -e "${RED}❌ Errors: $ERROR_COUNT${NC}"
echo -e "${BLUE}📊 Total repositories: $REPO_COUNT${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 Claude workflows have been added to $SUCCESS_COUNT repositories!${NC}"
    echo -e "${GREEN}   You can now use @claude in issues/PRs on these repos.${NC}\n"
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some repositories had errors. Please check manually.${NC}\n"
    exit 1
fi
