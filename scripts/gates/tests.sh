#!/bin/sh
# Gate (STORY_001, STORY_004): Flex builds and its tests pass before anything is pushed. On the
# iPhone 17 Pro simulator: unit tests (FlexTests) and the end-to-end workout flows
# (FlexUITests/WorkoutFlowUITests). On an Apple Watch simulator: the watch app's unit and UI tests
# (FlexWatchTests, FlexWatchUITests). The App Store screenshot captures (ScreenshotTests) are not
# tests and are left to scripts/screenshots.sh.
cd "$(dirname "$0")/../.." || exit 1

run_tests() { # label, scheme, destination, only-testing flags...
  label=$1; scheme=$2; destination=$3; shift 3
  log=$(mktemp)
  if ! xcodebuild test -project Flex/Flex.xcodeproj -scheme "$scheme" -destination "$destination" "$@" \
      -derivedDataPath .build/DerivedData -quiet > "$log" 2>&1; then
    echo "tests gate FAILED ($label):"
    # xcodebuild lists the red tests under "Failing tests:"; compile errors carry "error:".
    grep -E -A 20 "^Failing tests:" "$log" | grep -vE "IDELaunchParametersSnapshot|^\*\*|^$" | head -30
    grep -E "error:" "$log" | grep -vE "IDELaunchParametersSnapshot" | head -20
    echo
    echo "Rule: every push builds Flex and passes FlexTests, WorkoutFlowUITests, FlexWatchTests and"
    echo "FlexWatchUITests (CLAUDE.md, How features are built, item 6)."
    echo "Fix: run 'sh scripts/gates/tests.sh' and fix the failures above. A run that fails before"
    echo "any test starts (\"Simulator device failed to launch\", \"Busy\") is the simulator, not the"
    echo "code: 'xcrun simctl shutdown all' and run again; if it still refuses, erase the device"
    echo "('xcrun simctl list devices | grep \"iPhone 17 Pro\"', then 'xcrun simctl erase <udid>')."
    echo "Full log: $log"
    return 1
  fi
  rm -f "$log"
  echo "tests gate passed ($label)"
}

run_tests "iPhone" Flex 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FlexTests -only-testing:FlexUITests/WorkoutFlowUITests || exit 1
run_tests "Apple Watch" FlexWatch 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' \
  -only-testing:FlexWatchTests -only-testing:FlexWatchUITests || exit 1
echo "tests gate passed"
