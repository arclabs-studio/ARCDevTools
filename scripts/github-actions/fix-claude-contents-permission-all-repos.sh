#!/usr/bin/env bash

# Script to fix contents permission in claude.yml across all repos
# Changes contents: read -> contents: write

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ORG="arclabs-studio"
TEMP_DIR=$(mktemp -d)

PUBLIC_REPOS=(
    "ARCDevTools"
    "ARCDesignSystem"
    "ARCAuthentication"
    "ARCPurchasing"
    "ARCKnowledge"
    "ARCStorage"
    "ARCLinearGitHub-MCP"
    "ARCIntelligence"
    "ARCFirebase"
    "ARCMaps"
    "ARCNavigation"
    "ARCMetrics"
    "ARCNetworking"
    "ARCLogger"
)

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Fix Claude Contents Permission${NC}"
echo -e "${BLUE}================================================${NC}\n"

SUCCESS_COUNT=0
ERROR_COUNT=0
TOTAL=${#PUBLIC_REPOS[@]}

for REPO in "${PUBLIC_REPOS[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $REPO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    REPO_DIR="$TEMP_DIR/$REPO"

    echo -e "  ${BLUE}↓${NC} Cloning..."
    if ! git clone "https://github.com/$ORG/$REPO.git" "$REPO_DIR" --quiet 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone${NC}\n"
        ((ERROR_COUNT++))
        continue
    fi

    cd "$REPO_DIR"

    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@' 2>/dev/null || echo "main")
    git checkout "$DEFAULT_BRANCH" --quiet 2>/dev/null || { echo -e "  ${RED}❌ Failed to checkout${NC}\n"; ((ERROR_COUNT++)); cd - > /dev/null; continue; }

    if [[ ! -f ".github/workflows/claude.yml" ]]; then
        echo -e "  ${YELLOW}⊘ claude.yml doesn't exist${NC}\n"
        cd - > /dev/null
        continue
    fi

    if grep -q "contents: write" ".github/workflows/claude.yml"; then
        echo -e "  ${YELLOW}⊘ Already correct${NC}\n"
        cd - > /dev/null
        continue
    fi

    BRANCH_NAME="fix/claude-workflow-contents-permission"
    echo -e "  ${BLUE}🌿${NC} Creating branch..."
    git checkout -b "$BRANCH_NAME" --quiet

    echo -e "  ${BLUE}📝${NC} Updating permission..."
    sed -i.bak 's/contents: read/contents: write/' .github/workflows/claude.yml
    rm .github/workflows/claude.yml.bak 2>/dev/null || true

    git add .github/workflows/claude.yml

    if git diff --cached --quiet; then
        echo -e "  ${YELLOW}⊘ No changes${NC}\n"
        cd - > /dev/null
        continue
    fi

    echo -e "  ${BLUE}✓${NC} Committing..."
    git commit -m "fix(ci): update Claude workflow to contents: write

- Change contents: read -> write
- Allows Claude to create branches and make commits" --quiet

    echo -e "  ${BLUE}↑${NC} Pushing..."
    if ! git push origin "$BRANCH_NAME" --quiet 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to push${NC}\n"
        ((ERROR_COUNT++))
        cd - > /dev/null
        continue
    fi

    echo -e "  ${BLUE}📝${NC} Creating PR..."
    if gh pr create --repo "$ORG/$REPO" --base "$DEFAULT_BRANCH" --head "$BRANCH_NAME" \
      --title "fix(ci): update Claude workflow contents permission" \
      --body "Updates \`contents: write\` in claude.yml to allow Claude to create branches and commits." 2>&1 | grep -q "https://"; then
        echo -e "  ${GREEN}✅ Success${NC}\n"
        ((SUCCESS_COUNT++))
    else
        echo -e "  ${RED}❌ Failed to create PR${NC}\n"
        ((ERROR_COUNT++))
    fi

    cd - > /dev/null
done

rm -rf "$TEMP_DIR"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ PRs created: $SUCCESS_COUNT${NC}"
echo -e "${RED}❌ Errors: $ERROR_COUNT${NC}"
echo -e "${BLUE}📊 Total: $TOTAL${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 PRs created! Merging them now...${NC}\n"

    # Get PR numbers and merge them
    for REPO in "${PUBLIC_REPOS[@]}"; do
        PR_NUM=$(gh pr list --repo "$ORG/$REPO" --head "fix/claude-workflow-contents-permission" --json number --jq '.[0].number' 2>/dev/null)
        if [[ -n "$PR_NUM" ]]; then
            echo -e "${BLUE}Merging $REPO PR #$PR_NUM...${NC}"
            gh pr merge "$PR_NUM" --repo "$ORG/$REPO" --squash 2>&1 | grep -q "." && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
        fi
    done
fi
