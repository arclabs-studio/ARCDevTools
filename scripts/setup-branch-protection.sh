#!/bin/bash

# Setup Branch Protection for ARCDevTools
# This script configures branch protection rules for main and develop branches

set -e

REPO="arclabs-studio/ARCDevTools"

echo "🛡️  Setting up branch protection for $REPO"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "   Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "   Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to configure branch protection
configure_branch_protection() {
    local branch=$1
    local config=$2

    echo "📋 Configuring protection for '$branch' branch..."

    if gh api repos/$REPO/branches/$branch/protection \
        --method PUT \
        --input - <<< "$config" &> /dev/null; then
        echo "✅ Protection configured for '$branch'"
    else
        echo "⚠️  Could not configure protection for '$branch'"
        echo "   Branch may not exist or you may not have admin permissions"
    fi
}

# Configure main branch protection
MAIN_CONFIG=$(cat <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "SwiftLint",
      "SwiftFormat",
      "Validate Markdown Links",
      "Validate Branch Rules",
      "Build (macOS)",
      "Build (Linux)"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismissal_restrictions": {},
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
)

configure_branch_protection "main" "$MAIN_CONFIG"

# Configure develop branch protection
DEVELOP_CONFIG=$(cat <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "SwiftLint",
      "SwiftFormat",
      "Build (macOS)",
      "Build (Linux)"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
)

configure_branch_protection "develop" "$DEVELOP_CONFIG"

echo ""
echo "✅ Branch protection setup complete!"
echo ""
echo "📝 Summary:"
echo "  - main: Requires 1 approval + status checks + linear history"
echo "  - develop: Requires status checks only"
echo ""
echo "🔗 View settings: https://github.com/$REPO/settings/branches"
