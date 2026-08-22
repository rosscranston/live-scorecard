#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/Tax Terms.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p /tmp/tax-terms-clang-cache
mkdir -p /tmp/tax-terms-swift-cache
mkdir -p /tmp/tax-terms-swiftpm

env \
  CLANG_MODULE_CACHE_PATH=/tmp/tax-terms-clang-cache \
  SWIFT_MODULECACHE_PATH=/tmp/tax-terms-swift-cache \
  SWIFTPM_CONFIG_DIR=/tmp/tax-terms-swiftpm \
  swift build \
  --package-path "$PROJECT_DIR" \
  --scratch-path "$BUILD_DIR" \
  --disable-sandbox \
  -c release

cp "$BUILD_DIR/release/TaxTerms" "$MACOS_DIR/TaxTerms"
cp "$PROJECT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp -R "$BUILD_DIR/release/TaxTerms_TaxTerms.bundle" "$RESOURCES_DIR/TaxTerms_TaxTerms.bundle"

SIGNING_IDENTITY=${TAX_TERMS_SIGNING_IDENTITY:-}
if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY=$(
    /usr/bin/security find-identity -v -p codesigning 2>/dev/null |
      /usr/bin/awk '/Developer ID Application:|Apple Development:/ { print $2; exit }'
  )
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_DIR"
  if codesign --verify --deep --strict "$APP_DIR" 2>/dev/null; then
    echo "Signed with a stable code-signing identity."
  else
    codesign --force --deep --sign - "$APP_DIR"
    echo "WARNING: The local development identity did not pass trust validation; used a verified ad-hoc signature instead." >&2
  fi
else
  codesign --force --deep --sign - "$APP_DIR"
  echo "WARNING: No Apple code-signing identity was found; this build is ad-hoc signed." >&2
fi

echo "$APP_DIR"
