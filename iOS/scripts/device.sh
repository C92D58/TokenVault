#!/usr/bin/env bash
#
# Builds TokenVault for a connected iPhone, installs it, and launches it.
#
# Signing is a free Apple ID: Xcode ▸ Settings ▸ Accounts ▸ + ▸ Apple ID, signed in with
# x@wahsun.org. Automatic signing mints the profile; -allowProvisioningUpdates is passed so no
# clicking around in Signing & Capabilities is needed. Without the account the build stops with
# "No Accounts".
#
# Also required, on the phone:
#   • Settings ▸ Privacy & Security ▸ Developer Mode ▸ on (the phone reboots).
#   • Plug in, unlock, tap "Trust This Computer".
#
# A free account's profile lasts 7 days — re-run this script to renew it.
#
set -euo pipefail

DERIVED="${TV_DERIVED:-/tmp/tokenvault-ios-device-dd}"
BUNDLE_ID="dev.wahsun.tokenvault"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVICE_ID="${TV_DEVICE_ID:-}"
if [ -z "$DEVICE_ID" ]; then
    xcrun devicectl list devices --json-output /tmp/tv-devices.json >/dev/null 2>&1 || true
    DEVICE_ID="$(python3 - <<'PY'
import json
try:
    data = json.load(open('/tmp/tv-devices.json'))
except Exception:
    data = {}
for device in data.get('result', {}).get('devices', []):
    hardware = device.get('properties', {}).get('hardware', {})
    if hardware.get('reality') == 'simulated':
        continue
    print(device['identifier'])
    break
PY
)"
fi

[ -n "$DEVICE_ID" ] || {
    echo "No physical iPhone found."
    echo "  • is it plugged in, unlocked, and does the Mac have 'Trust This Computer'?"
    echo "  • is Developer Mode on (Settings ▸ Privacy & Security ▸ Developer Mode)?"
    exit 1
}

echo "== device $DEVICE_ID =="
xcrun devicectl list devices 2>/dev/null | grep "$DEVICE_ID" || true

echo "== building for the device =="
if ! xcodebuild -project "$ROOT/TokenVault.xcodeproj" -scheme TokenVault -configuration Debug \
    -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates build > /tmp/tokenvault-ios-device.log 2>&1; then
    grep -E "error:" /tmp/tokenvault-ios-device.log | head -20
    echo "build failed — full log at /tmp/tokenvault-ios-device.log"
    exit 1
fi

APP="$DERIVED/Build/Products/Debug-iphoneos/TokenVault.app"
[ -d "$APP" ] || { echo "no product at $APP"; exit 1; }

echo "== installing =="
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"

echo "== launching =="
xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID"

echo ""
echo "✅ TokenVault $(defaults read "$APP/Info" CFBundleShortVersionString 2>/dev/null || echo)" \
     "installed on the phone"
