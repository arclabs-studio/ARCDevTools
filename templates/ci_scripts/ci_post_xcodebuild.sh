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

# =============================================================================
# ARCDistribution — Metadata sync after successful archive
# =============================================================================
#
# Requires environment variables in App Store Connect:
#   ASC_KEY_ID       — API key ID (from Users and Access > Integrations)
#   ASC_ISSUER_ID    — API issuer ID
#   ASC_PRIVATE_KEY  — Base64-encoded .p8 private key content
#   APP_ID           — App Store Connect app ID (numeric)
#   METADATA_LOCALE  — Primary locale (default: en-US)
#
# The arc-distribution CLI is built during ci_post_clone.sh (see that script).
# If the CLI is not present, metadata sync is skipped (non-blocking).
# =============================================================================

if [ "${CI_XCODEBUILD_ACTION}" = "archive" ] && [ -n "${CI_ARCHIVE_PATH}" ]; then
  echo ""
  echo "📋 [ci_post_xcodebuild] Checking metadata sync conditions..."

  # Verify required env vars
  if [ -z "${ASC_KEY_ID}" ] || [ -z "${ASC_ISSUER_ID}" ] || [ -z "${ASC_PRIVATE_KEY}" ]; then
    echo "   ⚠️  ASC credentials not set — skipping metadata sync"
    echo "      Set ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY in App Store Connect env vars"
  elif [ -z "${APP_ID}" ]; then
    echo "   ⚠️  APP_ID not set — skipping metadata sync"
  else
    LOCALE="${METADATA_LOCALE:-en-US}"
    ARC_CLI_PATH="$CI_WORKSPACE/arc-distribution"

    if [ -f "$ARC_CLI_PATH" ]; then
      echo "   🔄 Syncing metadata for app $APP_ID [$LOCALE]..."

      # Validate metadata character counts
      "$ARC_CLI_PATH" validate-metadata --app-id "$APP_ID" --locale "$LOCALE" || {
        echo "   ❌ Metadata validation failed — sync skipped"
        echo "      Run: arc-distribution validate-metadata --app-id $APP_ID --locale $LOCALE"
        exit 1
      }

      # Sync metadata to App Store Connect
      "$ARC_CLI_PATH" metadata sync --app-id "$APP_ID" --locale "$LOCALE"
      echo "   ✅ Metadata synced for $APP_ID [$LOCALE]"

      # Sync additional locales if defined (space-separated list)
      if [ -n "${ADDITIONAL_LOCALES}" ]; then
        for EXTRA_LOCALE in $ADDITIONAL_LOCALES; do
          echo "   🔄 Syncing metadata [$EXTRA_LOCALE]..."
          "$ARC_CLI_PATH" metadata sync --app-id "$APP_ID" --locale "$EXTRA_LOCALE" || {
            echo "   ⚠️  Metadata sync failed for [$EXTRA_LOCALE] — continuing"
          }
        done
      fi

    else
      echo "   ℹ️  arc-distribution CLI not found at $ARC_CLI_PATH — skipping metadata sync"
      echo "      Build the CLI in ci_post_clone.sh to enable automatic metadata sync"
    fi
  fi
fi

echo ""
echo "✅ Post-build logging complete"
