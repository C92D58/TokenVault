#!/bin/bash
set -e

APP_NAME="TokenVault"
BUILD_DIR=".build"
TMP_DIR="/tmp/TokenVaultBuild"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SRC_DIR="Sources"

# Kill running instance
killall "$APP_NAME" 2>/dev/null || true

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
  -framework Carbon \
  -O \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  $SWIFT_FILES

cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "🔏 Signing..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/$APP_NAME.app/Contents"
cp -R "$APP_BUNDLE/Contents" "$TMP_DIR/$APP_NAME.app/"
codesign --force --deep --sign - "$TMP_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mv "$TMP_DIR/$APP_NAME.app" "$APP_BUNDLE"

echo ""
echo "✅ Build complete: $APP_BUNDLE"
echo "   Run: open $APP_BUNDLE"
