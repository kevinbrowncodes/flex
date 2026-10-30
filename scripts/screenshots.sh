#!/usr/bin/env bash
#
# Regenerates the App Store screenshots end to end:
#   1. runs the ScreenshotTests UI tests (demo data, dark theme, 9:41 status bar) on the
#      iPhone 6.9" and iPad 13" simulators, saving device-pixel PNGs to appstore/screenshots/raw/
#   2. composes captions + device frames with shotkit from appstore/screenshots/shots.json
#   3. verifies sizes / alpha / count for App Store Connect
#
# Usage: scripts/screenshots.sh [--capture-only|--render-only]
# Env:   KIT (path to appstore-screenshot-kit), IPHONE_SIM, IPAD_SIM (names or UDIDs), THEME (Dark|Light)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KIT="${KIT:-$ROOT/../appstore-screenshot-kit}"
SHOTKIT="$KIT/.build/release/shotkit"
IPHONE_SIM="${IPHONE_SIM:-iPhone 17 Pro Max}"        # 1320×2868
IPAD_SIM="${IPAD_SIM:-iPad Pro 13-inch (M5)}"        # 2064×2752
THEME="${THEME:-Dark}"
SHOTS="$ROOT/appstore/screenshots"
DERIVED="${DERIVED_DATA:-$ROOT/.build/DerivedData}"
MODE="${1:-all}"

udid_for() {
  if [[ "$1" =~ ^[0-9A-Fa-f-]{36}$ ]]; then echo "$1"; return; fi
  xcrun simctl list devices available | grep -F "$1 (" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

capture() {  # $1 = simulator, $2 = raw subfolder
  local udid; udid="$(udid_for "$1")"
  [[ -n "$udid" ]] || { echo "No simulator named '$1'" >&2; exit 1; }
  # Reboot for a clean state: no "back to <other app>" breadcrumb in the status bar, no stale overrides.
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override \
    --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
  rm -rf "$SHOTS/raw/$2"
  mkdir -p "$SHOTS/raw/$2"
  # TEST_RUNNER_<VAR> in xcodebuild's environment becomes <VAR> inside the UI test runner.
  env TEST_RUNNER_FLEX_SCREENSHOT_DIR="$SHOTS/raw/$2" \
      TEST_RUNNER_FLEX_SCREENSHOT_THEME="$THEME" \
    xcodebuild test \
      -project "$ROOT/Flex/Flex.xcodeproj" -scheme Flex \
      -destination "id=$udid" -derivedDataPath "$DERIVED" \
      -only-testing:FlexUITests/ScreenshotTests \
    | grep -E "Test Case.*(passed|failed|skipped)|error:|\*\* TEST" || true
  xcrun simctl status_bar "$udid" clear
  ls -1 "$SHOTS/raw/$2"
}

if [[ "$MODE" != "--render-only" ]]; then
  capture "$IPHONE_SIM" iphone
  capture "$IPAD_SIM" ipad
fi

if [[ "$MODE" != "--capture-only" ]]; then
  [[ -x "$SHOTKIT" ]] || (cd "$KIT" && swift build -c release)
  "$SHOTKIT" render "$SHOTS/shots.json"
  "$SHOTKIT" contact "$SHOTS/out"
  "$SHOTKIT" verify "$SHOTS/out"
fi
