#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/Private Call Notepad.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p /tmp/private-call-notepad-clang-cache
mkdir -p /tmp/private-call-notepad-swift-cache
mkdir -p /tmp/private-call-notepad-swiftpm

env \
  CLANG_MODULE_CACHE_PATH=/tmp/private-call-notepad-clang-cache \
  SWIFT_MODULECACHE_PATH=/tmp/private-call-notepad-swift-cache \
  SWIFTPM_CONFIG_DIR=/tmp/private-call-notepad-swiftpm \
  swift build \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$BUILD_DIR" \
  --disable-sandbox \
  -c release

cp "$BUILD_DIR/release/PrivateCallNotepad" "$MACOS_DIR/PrivateCallNotepad"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp "$PROJECT_DIR/Resources/Assets.car" "$RESOURCES_DIR/Assets.car"

SIGNING_IDENTITY=${PRIVATE_NOTEPAD_SIGNING_IDENTITY:-}
if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY=$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null |
      /usr/bin/awk -F '"' '/Developer ID Application:|Apple Development:/ { print $2; exit }'
  )
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_DIR"
  echo "Signed with a stable code-signing identity."
else
  codesign --force --deep --sign - "$APP_DIR"
  echo "WARNING: No Apple code-signing identity was found; this build is ad-hoc signed." >&2
fi

echo "$APP_DIR"
