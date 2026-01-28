#!/usr/bin/env bash

# Script to set CLAUDE_CODE_OAUTH_TOKEN secret in all public repositories
# Usage: ./setup-claude-secret-all-repos.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ORG="arclabs-studio"

# List of public repositories
PUBLIC_REPOS=(
    "ARCUIComponents"
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
echo -e "${BLUE}  Setup CLAUDE_CODE_OAUTH_TOKEN Secret${NC}"
echo -e "${BLUE}================================================${NC}\n"

echo -e "${YELLOW}This script will set the CLAUDE_CODE_OAUTH_TOKEN secret in all public repositories.${NC}\n"

# Get the token from the user
echo -e "${BLUE}📝 Please paste your Claude Code OAuth token:${NC}"
read -s CLAUDE_TOKEN

if [[ -z "$CLAUDE_TOKEN" ]]; then
    echo -e "\n${RED}❌ No token provided${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Token received${NC}\n"

# Counter
SUCCESS_COUNT=0
ERROR_COUNT=0
TOTAL=${#PUBLIC_REPOS[@]}

echo -e "${BLUE}📋 Setting secret in $TOTAL repositories...${NC}\n"

for REPO in "${PUBLIC_REPOS[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $REPO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "  ${BLUE}🔐${NC} Setting CLAUDE_CODE_OAUTH_TOKEN secret..."

    if echo "$CLAUDE_TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo "$ORG/$REPO" 2>&1; then
        echo -e "  ${GREEN}✅ Secret set successfully${NC}\n"
        ((SUCCESS_COUNT++))
    else
        echo -e "  ${RED}❌ Failed to set secret${NC}\n"
        ((ERROR_COUNT++))
    fi
done

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ Successfully configured: $SUCCESS_COUNT${NC}"
echo -e "${RED}❌ Errors: $ERROR_COUNT${NC}"
echo -e "${BLUE}📊 Total repositories: $TOTAL${NC}"
echo -e "${BLUE}================================================${NC}\n"

if [[ $SUCCESS_COUNT -eq $TOTAL ]]; then
    echo -e "${GREEN}🎉 All repositories configured successfully!${NC}"
    echo -e "${GREEN}   Claude workflows are now ready to use.${NC}\n"
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo -e "   1. Create an issue in any repo with '@claude' mention"
    echo -e "   2. Create a PR and get automatic code review"
    echo -e "   3. Tag @claude in PR comments for help\n"
elif [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some repositories could not be configured.${NC}"
    echo -e "${YELLOW}   Please check the errors above.${NC}\n"
else
    echo -e "${RED}❌ No repositories were configured.${NC}"
    echo -e "${RED}   Please check your permissions and try again.${NC}\n"
    exit 1
fi
