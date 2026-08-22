#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/Live Scorecard.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p /tmp/live-scorecard-clang-cache
mkdir -p /tmp/live-scorecard-swift-cache
mkdir -p /tmp/live-scorecard-swiftpm

env \
  CLANG_MODULE_CACHE_PATH=/tmp/live-scorecard-clang-cache \
  SWIFT_MODULECACHE_PATH=/tmp/live-scorecard-swift-cache \
  SWIFTPM_CONFIG_DIR=/tmp/live-scorecard-swiftpm \
  swift build \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$BUILD_DIR" \
  --disable-sandbox \
  -c release

cp "$BUILD_DIR/release/LiveScorecard" "$MACOS_DIR/LiveScorecard"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp "$PROJECT_DIR/Resources/Assets.car" "$RESOURCES_DIR/Assets.car"

SIGNING_IDENTITY=${LIVE_SCORECARD_SIGNING_IDENTITY:-}
if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY=$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null |
      /usr/bin/awk '/Developer ID Application:/ { print $2; exit }'
  )
fi

if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY=$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null |
      /usr/bin/awk '/Apple Development:/ { print $2; exit }'
  )
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign \
    --force \
    --deep \
    --options runtime \
    --entitlements "$PROJECT_DIR/Resources/LiveScorecard.entitlements" \
    --sign "$SIGNING_IDENTITY" \
    "$APP_DIR"
  echo "Signed with a stable code-signing identity."
else
  codesign --force --deep --sign - "$APP_DIR"
  echo "WARNING: No Apple code-signing identity was found; this build is ad-hoc signed." >&2
  echo "macOS recording permissions may need to be reset after the app is rebuilt." >&2
fi

echo "$APP_DIR"
