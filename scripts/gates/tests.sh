#!/bin/sh
# Gate (STORY_001): Flex builds and its tests pass before anything is pushed. Unit tests
# (FlexTests) and the end-to-end workout flows (FlexUITests/WorkoutFlowUITests) run on the
# iPhone 17 Pro simulator; the App Store screenshot captures (ScreenshotTests) are not tests
# and are left to scripts/screenshots.sh.
cd "$(dirname "$0")/../.." || exit 1
log=$(mktemp)
if ! xcodebuild test -project Flex/Flex.xcodeproj -scheme Flex \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:FlexTests -only-testing:FlexUITests/WorkoutFlowUITests \
    -derivedDataPath .build/DerivedData -quiet > "$log" 2>&1; then
  echo "tests gate FAILED:"
  # xcodebuild lists the red tests under "Failing tests:"; compile errors carry "error:".
  grep -E -A 20 "^Failing tests:" "$log" | grep -vE "IDELaunchParametersSnapshot|^\*\*|^$" | head -30
  grep -E "error:" "$log" | grep -vE "IDELaunchParametersSnapshot" | head -20
  echo
  echo "Rule: every push builds Flex and passes FlexTests and WorkoutFlowUITests (CLAUDE.md, How"
  echo "features are built, item 6)."
  echo "Fix: run 'sh scripts/gates/tests.sh' and fix the failures above. Full log: $log"
  exit 1
fi
rm -f "$log"
echo "tests gate passed"
