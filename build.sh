#!/bin/bash
set -e

APP="TokenVault"
BUILD=".build"
BUNDLE="$BUILD/$APP.app"
SRC="Sources"
ASSETS="Assets.xcassets"
RES="Resources"

# Kill running
killall "$APP" 2>/dev/null || true

rm -rf "$BUILD" /tmp/tv_build
mkdir -p "$BUNDLE/Contents/MacOS"
mkdir -p "$BUNDLE/Contents/Resources"

SDK=$(xcrun --show-sdk-path --sdk macosx)
TOOLCHAIN=$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain

echo "🔨 Compiling Swift..."
swiftc \
  -sdk "$SDK" \
  -target arm64-apple-macos14.0 \
  -F "$SDK/System/Library/Frameworks" \
  -framework SwiftUI -framework AppKit -framework Combine -framework Carbon \
  -O \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  $(find "$SRC" -name "*.swift" | sort)

echo "🎨 Compiling assets..."
mkdir -p /tmp/tv_build
actool "$ASSETS" \
  --compile "$BUNDLE/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist /tmp/tv_build/partial.plist \
  2>&1 | grep -v "^$" || true

# Merge partial plist into Info.plist
/usr/libexec/PlistBuddy -c "Merge /tmp/tv_build/partial.plist" "$RES/Info.plist" 2>/dev/null || true
cp "$RES/Info.plist" "$BUNDLE/Contents/Info.plist"

echo "🔏 Signing..."
xattr -cr "$BUNDLE" 2>/dev/null || true
codesign --force --deep --sign - "$BUNDLE"

echo ""
echo "✅ $BUNDLE"
echo "   open $BUNDLE"
