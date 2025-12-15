#!/bin/bash

# Setup GitHub Labels for ARCDevTools
# This script creates labels used by Release Drafter and PR categorization

set -e

REPO="arclabs-studio/ARCDevTools"

echo "🏷️  Setting up GitHub labels for $REPO"
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

# Function to create label if it doesn't exist
create_label() {
    local name=$1
    local color=$2
    local description=$3

    if gh label list --repo $REPO --limit 1000 | grep -q "^$name"; then
        echo "⏭️  Label '$name' already exists"
    else
        if gh label create "$name" \
            --repo $REPO \
            --color "$color" \
            --description "$description" &> /dev/null; then
            echo "✅ Created label '$name'"
        else
            echo "❌ Failed to create label '$name'"
        fi
    fi
}

echo "📋 Creating labels..."
echo ""

# Feature labels (green)
create_label "feature" "0E8A16" "New feature or enhancement"
create_label "enhancement" "0E8A16" "Enhancement to existing feature"

# Bug fix labels (red)
create_label "fix" "D73A4A" "Bug fix"
create_label "bugfix" "D73A4A" "Bug fix"
create_label "bug" "D73A4A" "Bug report"

# Documentation labels (blue)
create_label "documentation" "0075CA" "Documentation changes"
create_label "docs" "0075CA" "Documentation changes"

# Architecture labels (yellow)
create_label "architecture" "FBCA04" "Architecture or design changes"
create_label "refactor" "FBCA04" "Code refactoring"

# Maintenance labels (gray)
create_label "chore" "EDEDED" "Maintenance tasks"
create_label "dependencies" "EDEDED" "Dependency updates"

# Security labels (dark red)
create_label "security" "EE0701" "Security fix or improvement"

# Version labels (purple) - for semantic versioning
create_label "major" "5319E7" "Major version bump (breaking changes)"
create_label "minor" "5319E7" "Minor version bump (new features)"
create_label "patch" "5319E7" "Patch version bump (bug fixes)"

# Workflow labels (light gray)
create_label "automation" "C5DEF5" "CI/CD or automation related"
create_label "merge-conflict" "E99695" "Merge conflict needs resolution"

echo ""
echo "✅ Label setup complete!"
echo ""
echo "📝 Created labels for:"
echo "  - Release Drafter categorization"
echo "  - Semantic versioning"
echo "  - Workflow automation"
echo ""
echo "🔗 View labels: https://github.com/$REPO/labels"
