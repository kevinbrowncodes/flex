#!/usr/bin/env bash
#
# Regenerates the App Store screenshots end to end:
#   1. runs the ScreenshotTests UI tests (demo data, dark theme, 9:41 status bar) on the
#      iPhone 6.9" and iPad 13" simulators, saving device-pixel PNGs to appstore/screenshots/raw/
#   2. composes captions + device frames with shotkit from appstore/screenshots/shots.json
#   3. verifies sizes / alpha / count for App Store Connect
#   4. runs WatchScreenshotTests on the Apple Watch Series 11 (46mm) simulator and copies the raw
#      416×496 captures to appstore/screenshots/out-watch/ (no frame or caption on the watch;
#      shotkit knows no watch device), then checks them with scripts/gates/watch-screenshots.sh
#
# Usage: scripts/screenshots.sh [--capture-only|--render-only|--watch-only]
# Env:   KIT (path to appstore-screenshot-kit), IPHONE_SIM, IPAD_SIM, WATCH_SIM (names or UDIDs), THEME (Dark|Light)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KIT="${KIT:-$ROOT/../appstore-screenshot-kit}"
SHOTKIT="$KIT/.build/release/shotkit"
IPHONE_SIM="${IPHONE_SIM:-iPhone 17 Pro Max}"        # 1320×2868
IPAD_SIM="${IPAD_SIM:-iPad Pro 13-inch (M5)}"        # 2064×2752
WATCH_SIM="${WATCH_SIM:-Apple Watch Series 11 (46mm)}"  # 416×496
THEME="${THEME:-Dark}"
SHOTS="$ROOT/appstore/screenshots"
DERIVED="${DERIVED_DATA:-$ROOT/.build/DerivedData}"
MODE="${1:-all}"

udid_for() {
  if [[ "$1" =~ ^[0-9A-Fa-f-]{36}$ ]]; then echo "$1"; return; fi
  xcrun simctl list devices available | grep -F "$1 (" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

boot() {  # $1 = udid. Reboot for a clean state: no "back to <other app>" breadcrumb, no stale overrides.
  xcrun simctl shutdown "$1" 2>/dev/null || true
  xcrun simctl boot "$1"
  xcrun simctl bootstatus "$1" -b >/dev/null
}

capture() {  # $1 = simulator, $2 = raw subfolder
  local udid; udid="$(udid_for "$1")"
  [[ -n "$udid" ]] || { echo "No simulator named '$1'" >&2; exit 1; }
  boot "$udid"
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

capture_watch() {
  local udid; udid="$(udid_for "$WATCH_SIM")"
  [[ -n "$udid" ]] || { echo "No simulator named '$WATCH_SIM'" >&2; exit 1; }
  boot "$udid"
  rm -rf "$SHOTS/raw/watch"
  mkdir -p "$SHOTS/raw/watch"
  env TEST_RUNNER_FLEX_SCREENSHOT_DIR="$SHOTS/raw/watch" \
    xcodebuild test \
      -project "$ROOT/Flex/Flex.xcodeproj" -scheme FlexWatch \
      -destination "id=$udid" -derivedDataPath "$DERIVED" \
      -only-testing:FlexWatchUITests/WatchScreenshotTests \
    | grep -E "Test Case.*(passed|failed|skipped)|error:|\*\* TEST" || true
  ls -1 "$SHOTS/raw/watch"
}

publish_watch() {
  # The store shows watch screenshots as captured; the raw files are the files to upload.
  rm -rf "$SHOTS/out-watch"
  mkdir -p "$SHOTS/out-watch"
  cp "$SHOTS/raw/watch"/*.png "$SHOTS/out-watch/"
  sh "$ROOT/scripts/gates/watch-screenshots.sh"
}

if [[ "$MODE" == "--watch-only" ]]; then
  capture_watch
  publish_watch
  exit 0
fi

if [[ "$MODE" != "--render-only" ]]; then
  capture "$IPHONE_SIM" iphone
  capture "$IPAD_SIM" ipad
  capture_watch
fi

if [[ "$MODE" != "--capture-only" ]]; then
  [[ -x "$SHOTKIT" ]] || (cd "$KIT" && swift build -c release)
  # shotkit adds files and never removes them; a renumbered shot list would leave stale files
  # beside the new ones and push the set past the store's ten (STORY_013).
  for device in $(python3 -c 'import json, sys; print(" ".join(json.load(open(sys.argv[1]))["devices"]))' "$SHOTS/shots.json"); do
    rm -rf "$SHOTS/out/$device"
  done
  "$SHOTKIT" render "$SHOTS/shots.json"
  "$SHOTKIT" contact "$SHOTS/out"
  "$SHOTKIT" verify "$SHOTS/out"
  [[ -d "$SHOTS/raw/watch" ]] && publish_watch
fi
