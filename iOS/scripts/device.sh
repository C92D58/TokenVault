#!/usr/bin/env bash
#
# Builds TokenVault for a connected iPhone, installs it, and launches it.
#
#   ./scripts/device.sh                 # first physical iPhone found
#   TV_DEVICE_ID=00008120-000A64D00E87A01E ./scripts/device.sh
#
# Signing uses the paid team MAA6W8AG5P (Apple ID wahsun@vip.qq.com), signed in under
# Xcode ▸ Settings ▸ Accounts. Automatic signing mints the profile; -allowProvisioningUpdates
# is passed so no clicking in Signing & Capabilities is needed. Without the account the build
# stops with "No Accounts"; a team mismatch stops with "does not support provisioning".
#
# Also required, on the phone:
#   • Settings ▸ Privacy & Security ▸ Developer Mode ▸ on (the phone reboots).
#   • Plug in, unlock, tap "Trust This Computer".
#
# The profile lasts a year (paid team) — re-run this script before it expires.
#
set -euo pipefail

DERIVED="${TV_DERIVED:-/tmp/tokenvault-ios-device-dd}"
BUNDLE_ID="dev.wahsun.tokenvault"
# The team that actually has a signed-in account in Xcode (Accounts settings) — read from Xcode's
# own preferences instead of hardcoding. `grep -o` + `|| true` so a preferences format change
# cannot kill the script under `set -euo pipefail` (it did: the pipeline returned no match).
TEAM="${TV_TEAM:-}"
if [ -z "$TEAM" ]; then
    TEAM="$(defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null \
        | grep -o 'teamID = [A-Z0-9]\{10\}' | head -1 | awk '{print $3}')" || true
fi
TEAM="${TEAM:-MAA6W8AG5P}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEVICE_ID="${TV_DEVICE_ID:-}"
if [ -z "$DEVICE_ID" ]; then
    xcrun devicectl list devices --json-output /tmp/tv-devices.json >/dev/null 2>&1 || true
    # devicectl's JSON moved to `properties.hardware` (the old top-level hardwareProperties is
    # deprecated); the value xcodebuild and devicectl both accept is `properties.hardware.udid`.
    DEVICE_ID="$(python3 - <<'PY'
import json
try:
    data = json.load(open('/tmp/tv-devices.json'))
except Exception:
    data = {}
for device in data.get('result', {}).get('devices', []):
    hardware = device.get('properties', {}).get('hardware') or device.get('hardwareProperties', {})
    if hardware.get('reality') != 'physical':
        continue
    udid = hardware.get('udid') or device.get('identifier')
    print(udid)
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
xcrun devicectl list devices 2>/dev/null | grep -v simulated | grep -iE "iphone|ipad" || true

echo "== generating app icon =="
swift "$ROOT/../scripts/make-icon.swift" ios \
    "$ROOT/TokenVault/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" > /dev/null

# iCloud Drive restores files with fresh/odd timestamps, which lets the build system skip an
# edited file. Touch the sources so the build always matches the disk.
find "$ROOT/TokenVault" "$ROOT/../Sources/Core" -name "*.swift" -exec touch {} +

echo "== building for the device (team $TEAM) =="
if ! xcodebuild -project "$ROOT/TokenVault.xcodeproj" -scheme TokenVault -configuration Debug \
    -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" \
    -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" \
    build > /tmp/tokenvault-ios-device.log 2>&1; then
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
echo "✅ TokenVault installed on $DEVICE_ID"
echo "   lock screen → Face ID → 保險庫"
