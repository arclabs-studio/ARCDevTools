#!/usr/bin/env bash

# Script to add Claude workflows via Pull Request for repos with protected branches
# Usage: ./add-claude-workflows-via-pr.sh <repo-name1> <repo-name2> ...

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
BRANCH_NAME="chore/add-claude-workflows-$(date +%s)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Adding Claude Workflows via Pull Request${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Check if workflow files exist
if [[ ! -f "$SOURCE_WORKFLOWS_DIR/claude.yml" ]] || [[ ! -f "$SOURCE_WORKFLOWS_DIR/claude-code-review.yml" ]]; then
    echo -e "${RED}❌ Error: Workflow files not found in $SOURCE_WORKFLOWS_DIR${NC}"
    echo -e "${RED}   Please run this script from the FavRes-iOS directory${NC}"
    exit 1
fi

# Check if repos were provided
if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: $0 <repo-name1> <repo-name2> ...${NC}"
    echo -e "${YELLOW}Example: $0 ARCUIComponents ARCDevTools ARCKnowledge${NC}"
    exit 1
fi

REPOS=("$@")
echo -e "${GREEN}✅ Processing ${#REPOS[@]} repositories${NC}\n"

# Counter for processed repos
SUCCESS_COUNT=0
ERROR_COUNT=0

# Process each repository
for REPO in "${REPOS[@]}"; do
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
        cd - > /dev/null
        continue
    fi

    # Create new branch
    echo -e "  ${BLUE}🌿${NC} Creating branch: $BRANCH_NAME..."
    git checkout -b "$BRANCH_NAME" --quiet

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
        --title "chore(ci): add Claude GitHub Actions workflows" \
        --body "## Summary

This PR adds Claude Code GitHub Actions workflows to enable AI-powered automation.

## Changes

- ✅ **claude.yml**: Responds to \`@claude\` mentions in issues and PRs
- ✅ **claude-code-review.yml**: Automated code reviews on pull requests

## Features

- 🤖 Mention \`@claude\` in any issue or PR comment to get AI assistance
- 📝 Automatic PR reviews focused on:
  - Code quality
  - Potential bugs
  - ARC Labs Swift standards
  - Architecture, testing, error handling

## Requirements

- ✅ Claude GitHub App already installed
- ✅ \`CLAUDE_CODE_OAUTH_TOKEN\` secret configured
- ✅ Workflows will run on GitHub Actions (free for public repos)

## Testing

Once merged, test by:
1. Creating a new PR
2. Adding a comment with \`@claude review this PR\`
3. Observing the automated response

---

**Note**: This repo is public, so GitHub Actions will work without additional configuration." 2>&1)

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
echo -e "${RED}❌ Errors: $ERROR_COUNT${NC}"
echo -e "${BLUE}📊 Total repositories: ${#REPOS[@]}${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 Pull Requests have been created!${NC}"
    echo -e "${GREEN}   Review and merge them to enable Claude workflows.${NC}\n"
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some repositories had errors. Please check manually.${NC}\n"
    exit 1
fi
