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
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"
mkdir -p /tmp/tv_build

SDK=$(xcrun --show-sdk-path --sdk macosx)

echo "🔨 Compiling..."
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
xattr -cr "$BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$BUNDLE"

echo ""
echo "✅ $BUNDLE"
echo "   open $BUNDLE"
