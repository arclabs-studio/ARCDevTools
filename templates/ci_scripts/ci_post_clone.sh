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
echo "🔍 Installing pinned SwiftLint..."
# Pinned via .arc-tool-versions (ARCDevTools/configs/tool-versions) and
# installed into .arc-tools/bin. Do NOT `brew install swiftlint` — brew has no
# versioned formula, so it drifts to latest and produces lint results that
# disagree with developer machines and GitHub Actions.
if [ -x "./ARCDevTools/scripts/install-tools.sh" ]; then
  ./ARCDevTools/scripts/install-tools.sh swiftlint
  # Each ci_script and Xcode build phase runs in its own process, so exporting
  # PATH here would not survive. Symlink into a directory already on PATH so
  # "Run Script" build phases calling bare `swiftlint` get the pinned binary.
  mkdir -p /usr/local/bin
  ln -sf "$(pwd)/.arc-tools/bin/swiftlint" /usr/local/bin/swiftlint
  echo "✅ SwiftLint $(swiftlint version) (pinned)"
else
  echo "⚠️  ARCDevTools/scripts/install-tools.sh not found."
  echo "    Is the ARCDevTools submodule checked out? Falling back to PATH."
  command -v swiftlint >/dev/null 2>&1 && echo "   SwiftLint $(swiftlint version) (unpinned)"
fi

echo ""
echo "✅ Post-clone setup complete"
