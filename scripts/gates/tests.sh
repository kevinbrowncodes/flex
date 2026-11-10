#!/bin/sh
# Gate (STORY_001, STORY_004): Flex builds and its tests pass before anything is pushed. On the
# iPhone 17 Pro simulator: unit tests (FlexTests) and the end-to-end workout flows
# (FlexUITests/WorkoutFlowUITests). On an Apple Watch simulator: the watch app's unit and UI tests
# (FlexWatchTests, FlexWatchUITests). The App Store screenshot captures (ScreenshotTests) are not
# tests and are left to scripts/screenshots.sh.
cd "$(dirname "$0")/../.." || exit 1

# xcodebuild resolves a bare device name against the newest installed runtime ("OS:latest") and
# fails when that runtime has no such device: Xcode 27.2 brought iOS 27.2 with no iPhone 17 Pro,
# and the gate died before a single test ran (CHORE_004, 2026-11-10). So the gate resolves the
# name itself, to the device on the newest runtime that has it, and hands xcodebuild the id.
device_id() { # platform (iOS or watchOS), device name -> "udid version", or nothing
  xcrun simctl list devices available -j | python3 -I -c '
import json, sys
platform, name = sys.argv[1], sys.argv[2]
best = None
for runtime, items in json.load(sys.stdin)["devices"].items():
    marker = ".SimRuntime." + platform + "-"
    if marker not in runtime:
        continue
    version = []
    for part in runtime.split(marker, 1)[1].split("-"):
        if not part.isdigit():
            break
        version.append(int(part))
    for device in items:
        if device["name"] == name and device.get("isAvailable", True):
            if best is None or tuple(version) > best[0]:
                best = (tuple(version), device["udid"])
if best:
    print(best[1], ".".join(str(v) for v in best[0]))
' "$1" "$2"
}

resolve() { # platform, name -> sets DEVICE_ID, or fails with the rule and the fix
  found=$(device_id "$1" "$2")
  if [ -z "$found" ]; then
    echo "tests gate FAILED: no '$2' simulator is installed on any $1 runtime."
    echo "Rule: the tests run on the simulators README.md names: the iPhone 17 Pro and the"
    echo "Apple Watch Series 11 (46mm), on whichever runtime has them (CHORE_004)."
    echo "Fix: add the device in Xcode > Settings > Components, or"
    echo "'xcrun simctl create \"$2\" \"$2\" <runtime from xcrun simctl list runtimes>', then run again."
    return 1
  fi
  DEVICE_ID=${found%% *}
  echo "tests gate: '$2' is $DEVICE_ID on $1 ${found#* }"
}

failures() { # the failure messages in the newest result bundle, which xcodebuild -quiet hides
  bundle=$(ls -td .build/DerivedData/Logs/Test/*.xcresult 2>/dev/null | head -1)
  [ -n "$bundle" ] || return 0
  xcrun xcresulttool get test-results summary --path "$bundle" 2>/dev/null | python3 -I -c '
import json, sys
summary = json.load(sys.stdin)
for failure in summary.get("testFailures", [])[:12]:
    text = " ".join((failure.get("failureText") or "").split())
    print("  " + failure.get("testName", "?") + ": " + text[:240])
'
}

run_tests() { # label, scheme, destination, only-testing flags...
  label=$1; scheme=$2; destination=$3; shift 3
  log=$(mktemp)
  if ! xcodebuild test -project Flex/Flex.xcodeproj -scheme "$scheme" -destination "$destination" "$@" \
      -derivedDataPath .build/DerivedData -quiet > "$log" 2>&1; then
    echo "tests gate FAILED ($label):"
    # xcodebuild lists the red tests under "Failing tests:"; compile errors carry "error:".
    grep -E -A 20 "^Failing tests:" "$log" | grep -vE "IDELaunchParametersSnapshot|^\*\*|^$" | head -30
    grep -E "error:" "$log" | grep -vE "IDELaunchParametersSnapshot|exit code 0 but produced no further output" | head -20
    failures
    echo
    echo "Ten UI tests timing out together while another xcodebuild test runs on this Mac is a starved"
    echo "simulator, not the code: wait for it ('pgrep -fl \"xcodebuild test\"') and run again (CHORE_004)."
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

resolve iOS "iPhone 17 Pro" || exit 1
iphone=$DEVICE_ID
resolve watchOS "Apple Watch Series 11 (46mm)" || exit 1
watch=$DEVICE_ID
if [ "$1" = "--devices" ]; then exit 0; fi # the resolution alone, for CHORE_004's check

run_tests "iPhone" Flex "platform=iOS Simulator,id=$iphone" \
  -only-testing:FlexTests -only-testing:FlexUITests/WorkoutFlowUITests || exit 1
run_tests "Apple Watch" FlexWatch "platform=watchOS Simulator,id=$watch" \
  -only-testing:FlexWatchTests -only-testing:FlexWatchUITests || exit 1
echo "tests gate passed"
