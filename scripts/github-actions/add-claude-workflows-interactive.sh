#!/usr/bin/env bash

# Interactive script to add Claude workflows to selected ARC Labs repositories
# Usage: ./add-claude-workflows-interactive.sh

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
echo -e "${BLUE}  Adding Claude Workflows (Interactive Mode)${NC}"
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

# Convert to array (compatible with bash and zsh)
REPO_ARRAY=()
while IFS= read -r line; do
    REPO_ARRAY+=("$line")
done <<< "$PUBLIC_REPOS"
REPO_COUNT=${#REPO_ARRAY[@]}

echo -e "${GREEN}✅ Found $REPO_COUNT public repositories${NC}\n"
echo -e "${YELLOW}Select repositories to add workflows (space to select, enter to confirm):${NC}\n"

# Show list with numbers
for i in "${!REPO_ARRAY[@]}"; do
    echo -e "  $((i+1)). ${REPO_ARRAY[$i]}"
done

echo -e "\n${BLUE}Options:${NC}"
echo -e "  ${GREEN}a${NC} - Add to all repositories"
echo -e "  ${GREEN}1,2,3${NC} - Add to specific repositories (comma-separated numbers)"
echo -e "  ${GREEN}1-5${NC} - Add to range of repositories"
echo -e "  ${GREEN}q${NC} - Quit"

echo -e -n "\n${YELLOW}Enter your choice: ${NC}"
read -r CHOICE

# Parse choice
SELECTED_REPOS=()

if [[ "$CHOICE" == "q" ]] || [[ "$CHOICE" == "Q" ]]; then
    echo -e "${YELLOW}Cancelled by user${NC}"
    exit 0
elif [[ "$CHOICE" == "a" ]] || [[ "$CHOICE" == "A" ]]; then
    SELECTED_REPOS=("${REPO_ARRAY[@]}")
elif [[ "$CHOICE" =~ ^[0-9,\-]+$ ]]; then
    # Handle comma-separated and ranges
    IFS=',' read -ra PARTS <<< "$CHOICE"
    for PART in "${PARTS[@]}"; do
        if [[ "$PART" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # Range
            START=${BASH_REMATCH[1]}
            END=${BASH_REMATCH[2]}
            for ((i=START; i<=END; i++)); do
                if [[ $i -ge 1 ]] && [[ $i -le $REPO_COUNT ]]; then
                    SELECTED_REPOS+=("${REPO_ARRAY[$((i-1))]}")
                fi
            done
        else
            # Single number
            NUM=$PART
            if [[ $NUM -ge 1 ]] && [[ $NUM -le $REPO_COUNT ]]; then
                SELECTED_REPOS+=("${REPO_ARRAY[$((NUM-1))]}")
            fi
        fi
    done
else
    echo -e "${RED}❌ Invalid choice${NC}"
    exit 1
fi

if [[ ${#SELECTED_REPOS[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No repositories selected${NC}"
    exit 0
fi

echo -e "\n${GREEN}✅ Selected ${#SELECTED_REPOS[@]} repositories:${NC}"
for REPO in "${SELECTED_REPOS[@]}"; do
    echo -e "  • $REPO"
done

echo -e -n "\n${YELLOW}Proceed? (y/N): ${NC}"
read -r CONFIRM

if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
    echo -e "${YELLOW}Cancelled by user${NC}"
    exit 0
fi

echo ""

# Counter for processed repos
SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# Process each selected repository
for REPO in "${SELECTED_REPOS[@]}"; do
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

done

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
echo -e "${BLUE}📊 Selected repositories: ${#SELECTED_REPOS[@]}${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 Claude workflows have been added to $SUCCESS_COUNT repositories!${NC}"
    echo -e "${GREEN}   You can now use @claude in issues/PRs on these repos.${NC}\n"
fi

if [[ $ERROR_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some repositories had errors. Please check manually.${NC}\n"
    exit 1
fi
