#!/bin/bash
set -e

APP="TokenVault"
BUILD=".build"
BUNDLE="$BUILD/$APP.app"
SRC="Sources"
ASSETS="Assets.xcassets"
RES="Resources"

killall "$APP" 2>/dev/null || true

rm -rf "$BUILD" /tmp/tv_build
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources" /tmp/tv_build

SDK=$(xcrun --show-sdk-path --sdk macosx)

echo "🔨 Compiling (macOS)..."
swiftc \
  -sdk "$SDK" \
  -target arm64-apple-macos14.0 \
  -framework SwiftUI -framework AppKit -framework Combine \
  -framework CryptoKit -framework LocalAuthentication \
  -framework Security -framework Carbon \
  -O \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  $(find "$SRC" -name "*.swift" | sort)

echo "🎨 Assets..."
actool "$ASSETS" --compile "$BUNDLE/Contents/Resources" \
  --platform macosx --minimum-deployment-target 14.0 \
  --app-icon AppIcon --output-partial-info-plist /tmp/tv_build/partial.plist 2>&1 | tail -1

cp "$RES/Info.plist" "$BUNDLE/Contents/Info.plist"

echo "🔏 Signing..."
# Sign in /tmp to avoid iCloud extended attributes
rm -rf /tmp/tv_sign
mkdir -p /tmp/tv_sign/$APP.app/Contents
cp -R "$BUNDLE/Contents" /tmp/tv_sign/$APP.app/
codesign --force --deep --sign - /tmp/tv_sign/$APP.app
rm -rf "$BUNDLE"
mv /tmp/tv_sign/$APP.app "$BUNDLE"

echo ""
echo "✅ $BUNDLE"
echo "   open $BUNDLE"
