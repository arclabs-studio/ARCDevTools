#!/bin/sh
set -e

echo "🔨 [ci_pre_xcodebuild] Preparing build..."
echo "   Action:   ${CI_XCODEBUILD_ACTION:-unknown}"
echo "   Platform: ${CI_PRODUCT_PLATFORM:-unknown}"

if [ "${CI_XCODEBUILD_ACTION}" = "archive" ]; then
  echo "   📦 Preparing release archive"
fi
if [ -n "${CI_PULL_REQUEST_NUMBER}" ]; then
  echo "   🔀 PR build #${CI_PULL_REQUEST_NUMBER}"
fi
if [ -n "${CI_TAG}" ]; then
  echo "   🏷️  Tag build: ${CI_TAG}"
fi

echo ""
echo "✅ Pre-build checks complete"
