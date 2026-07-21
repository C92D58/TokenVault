#!/bin/bash
set -e

APP_NAME="TokenVault"
BUILD_DIR=".build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SRC_DIR="Sources"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "🔨 Compiling..."
SWIFT_FILES=$(find "$SRC_DIR" -name "*.swift" | sort)
SDK_PATH=$(xcrun --show-sdk-path)

swiftc \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos14.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework Combine \
  -O \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  $SWIFT_FILES

cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"

echo "🔏 Signing..."
xattr -cr "$APP_BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "✅ Build complete: $APP_BUNDLE"
echo "   Run: open $APP_BUNDLE"
