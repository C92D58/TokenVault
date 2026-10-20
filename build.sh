#!/bin/bash
set -e

APP="TokenVault"
BUILD=".build"
BUNDLE="$BUILD/$APP.app"
SRC="Sources"
ASSETS="Assets.xcassets"
RES="Resources"

killall "$APP" 2>/dev/null || true

rm -rf "$BUILD" /tmp/tv_build /tmp/tv_sign
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources" /tmp/tv_build

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

# Privacy manifest — App Store Connect rejects uploads (ITMS-91053) without it.
if [ -f "$RES/PrivacyInfo.xcprivacy" ]; then
  cp "$RES/PrivacyInfo.xcprivacy" "$BUNDLE/Contents/Resources/PrivacyInfo.xcprivacy"
fi

# Embed provisioning profile if exists
if [ -f "$RES/embedded.provisionprofile" ]; then
  cp "$RES/embedded.provisionprofile" "$BUNDLE/Contents/embedded.provisionprofile"
fi

echo "🔏 Signing (Hardened Runtime)..."
mkdir -p /tmp/tv_sign/$APP.app/Contents
cp -R "$BUNDLE/Contents" /tmp/tv_sign/$APP.app/

# An ad-hoc signature may not carry com.apple.developer.* entitlements — AMFI kills the process
# at launch ("Killed: 9"). Keep the real file for App Store/notarized signing, sign the local
# build with a copy that has the iCloud keys stripped, so iCloud reports itself unavailable
# instead of taking the whole app down.
LOCAL_ENTITLEMENTS=/tmp/tv_local.entitlements
cp "$RES/TokenVault.entitlements" "$LOCAL_ENTITLEMENTS"
for key in com.apple.developer.icloud-container-identifiers \
           com.apple.developer.icloud-services \
           com.apple.developer.ubiquity-kvstore-identifier; do
  /usr/libexec/PlistBuddy -c "Delete :$key" "$LOCAL_ENTITLEMENTS" >/dev/null 2>&1 || true
done

# Sign with hardened runtime flags
codesign --force --deep --sign - \
  --options runtime \
  --entitlements "$LOCAL_ENTITLEMENTS" \
  --timestamp \
  /tmp/tv_sign/$APP.app

rm -rf "$BUNDLE"
mv /tmp/tv_sign/$APP.app "$BUNDLE"

echo ""
echo "✅ $BUNDLE"
echo ""
echo "   🏪 App Store 驗證："
echo "   codesign -dvvv --entitlements - \"$BUNDLE\""
echo "   spctl -a -t exec -vv \"$BUNDLE\""
