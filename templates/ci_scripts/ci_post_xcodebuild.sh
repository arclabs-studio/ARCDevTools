#!/bin/sh
set -e

echo "✅ [ci_post_xcodebuild] Build complete"
echo "   Action: ${CI_XCODEBUILD_ACTION:-unknown}"

if [ -n "${CI_ARCHIVE_PATH}" ]; then
  echo "   📦 Archive path: ${CI_ARCHIVE_PATH}"
fi
if [ -n "${CI_TEST_RESULTS_PATH}" ]; then
  echo "   🧪 Test results: ${CI_TEST_RESULTS_PATH}"
fi

echo ""
echo "✅ Post-build logging complete"
