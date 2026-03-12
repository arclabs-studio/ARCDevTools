#!/bin/sh
set -e

echo "🚀 [ci_post_clone] Starting post-clone setup..."
echo "   Branch:    ${CI_BRANCH:-unknown}"
echo "   Workflow:  ${CI_WORKFLOW:-unknown}"
echo "   Build #:   ${CI_BUILD_NUMBER:-unknown}"
echo "   Commit:    ${CI_COMMIT:-unknown}"

echo ""
echo "📦 Verifying Package.resolved is present..."
RESOLVED="FavRes-iOS/FavRes-iOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ ! -f "$RESOLVED" ]; then
  echo "❌ Package.resolved not found — SPM dependencies may fail to resolve"
  exit 1
fi
echo "✅ Package.resolved found"

echo ""
echo "🔍 Checking SwiftLint availability..."
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "   SwiftLint not found, installing via Homebrew..."
  brew install swiftlint
else
  echo "✅ SwiftLint $(swiftlint version)"
fi

echo ""
echo "✅ Post-clone setup complete"
