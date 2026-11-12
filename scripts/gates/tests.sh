#!/bin/sh
# Gate (STORY_001, STORY_004, CHORE_004, CHORE_005): Flex builds and its tests pass before anything
# is pushed, on simulators of Flex's own so no other repo installs onto them:
#   Flex Gate           the newest iOS runtime, iPhone 17 Pro or the newest type it supports:
#                       FlexTests and the end-to-end workout flows (FlexUITests/WorkoutFlowUITests) and Settings' account and Health (AccountUITests, STORY_015)
#   Flex Watch Gate     the newest watchOS runtime: FlexWatchTests and FlexWatchUITests
#   Flex Gate 18        the oldest installed runtime of the iOS floor (IPHONEOS_DEPLOYMENT_TARGET):
#                       FlexTests and one smoke UI test
#   Flex Watch Gate 11  the oldest installed runtime of the watchOS floor: FlexWatchTests and one
#                       smoke UI test
# The two floor devices prove the oldest iPhone and watch Flex ships to still build and launch. A
# floor runtime Apple no longer offers (watchOS 11 under Xcode 27.2, 2026-11-10) falls back to the
# oldest installed one, named for it ("Flex Watch Gate 26"), and the gate says so every run. The
# App Store screenshot captures (ScreenshotTests, WatchScreenshotTests, PreviewTests) are not tests
# and are left to scripts/screenshots.sh and scripts/preview.sh, on the stock simulators.
cd "$(dirname "$0")/../.." || exit 1

PBX=Flex/Flex.xcodeproj/project.pbxproj
IOS_FLOOR=$(sed -n 's/.*IPHONEOS_DEPLOYMENT_TARGET = \([0-9]*\).*/\1/p' "$PBX" | head -1)
WATCH_FLOOR=$(sed -n 's/.*WATCHOS_DEPLOYMENT_TARGET = \([0-9]*\).*/\1/p' "$PBX" | head -1)

# xcodebuild resolves a bare device name against the newest installed runtime ("OS:latest") and
# fails when that runtime has no such device: Xcode 27.2 brought iOS 27.2 with no iPhone 17 Pro,
# and the gate died before a single test ran (CHORE_004, 2026-11-10). So the gate resolves names
# itself and hands xcodebuild device ids.
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

# The runtime for a device: "newest", or the oldest installed runtime of a major version. Prints
# "identifier version" and the device type identifiers it supports, one per line after that.
runtime_pick() { # platform, newest|<major>
  xcrun simctl list runtimes -j | python3 -I -c '
import json, sys
platform, want = sys.argv[1], sys.argv[2]
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and r["identifier"].split(".SimRuntime.")[1].startswith(platform + "-")]
def version(r): return tuple(int(p) for p in r["version"].split("."))
if want == "newest":
    pick = max(runtimes, key=version, default=None)
elif want == "oldest":
    pick = min(runtimes, key=version, default=None)
else:
    floor = [r for r in runtimes if version(r)[0] == int(want)]
    pick = min(floor, key=version, default=None)
if pick:
    print(pick["identifier"], pick["version"])
    for t in pick.get("supportedDeviceTypes", []):
        print(t["identifier"])
' "$1" "$2"
}

# Finds the gate device by name, or creates it on the runtime asked for with the first device type
# the runtime supports from the preference list. Sets DEVICE_ID; fails with the rule and the fix.
# A floor device ("<name> <major>") whose major Apple no longer offers for download falls back to
# the oldest installed runtime of the platform, and the gate says so on every run.
ensure_device() { # name, platform, newest|<major>, type preference...
  name=$1; platform=$2; want=$3; shift 3
  base=$name
  [ "$want" = "newest" ] || name="$base $want"
  found=$(device_id "$platform" "$name")
  if [ -n "$found" ]; then
    DEVICE_ID=${found%% *}; DEVICE_OS=${found#* }
    echo "tests gate: '$name' is $DEVICE_ID on $platform $DEVICE_OS"
    return 0
  fi
  picked=$(runtime_pick "$platform" "$want")
  if [ -z "$picked" ] && [ "$want" != "newest" ]; then
    # The floor's major is not installed. A fallback device from an earlier run means Apple was
    # already asked and had none; otherwise ask once, then fall back to the oldest installed runtime.
    oldest=$(runtime_pick "$platform" oldest | head -1 | cut -d' ' -f2)
    fallback="$base ${oldest%%.*}"
    found=$(device_id "$platform" "$fallback")
    if [ -z "$found" ]; then
      echo "tests gate: no $platform $want runtime is installed; asking Apple for one (once per Mac)"
      for minor in 0 1 2 3 4 5 6; do
        xcodebuild -downloadPlatform "$platform" -buildVersion "$want.$minor" >/dev/null 2>&1 && break
      done
      picked=$(runtime_pick "$platform" "$want")
    fi
    if [ -z "$picked" ]; then
      echo "tests gate: Apple offers no $platform $want simulator for this Xcode; the floor run falls back to"
      echo "the oldest installed runtime, $platform $oldest, as '$fallback'. The real floor ($want) is covered"
      echo "by hand on a device (CHORE_003) until Apple offers the runtime again or the floor moves (CHORE_005)."
      name=$fallback
      if [ -n "$found" ]; then
        DEVICE_ID=${found%% *}; DEVICE_OS=${found#* }
        echo "tests gate: '$name' is $DEVICE_ID on $platform $DEVICE_OS"
        return 0
      fi
      picked=$(runtime_pick "$platform" oldest)
    fi
  fi
  if [ -z "$picked" ]; then
    echo "tests gate FAILED: no $platform runtime for '$name' is installed at all."
    echo "Rule: the tests run on Flex's own simulators, the newest $platform and the oldest supported"
    echo "one, so the oldest device Flex ships to is built and launched on every push (CHORE_005)."
    echo "Fix: Xcode > Settings > Components, install a $platform simulator runtime, then run again."
    return 1
  fi
  runtime=$(echo "$picked" | head -1 | cut -d' ' -f1)
  version=$(echo "$picked" | head -1 | cut -d' ' -f2)
  type=""
  for pref in "$@"; do
    if echo "$picked" | tail -n +2 | grep -qx "com.apple.CoreSimulator.SimDeviceType.$pref"; then
      type="com.apple.CoreSimulator.SimDeviceType.$pref"; break
    fi
  done
  if [ -z "$type" ]; then
    echo "tests gate FAILED: $runtime supports none of: $*."
    echo "Rule: as above (CHORE_005). Fix: add a device type that runtime supports to the preference list in scripts/gates/tests.sh."
    return 1
  fi
  DEVICE_ID=$(xcrun simctl create "$name" "$type" "$runtime") || return 1
  DEVICE_OS=$version
  echo "tests gate: created '$name' ($type) on $platform $version: $DEVICE_ID"
  # A device's first boot is slow and its first test run raced it on 2026-11-10 (the iPhone's test
  # runner died mid-suite; the watch app was "Unknown" to the watch when the runner asked for it).
  # Boot it to completion once here, before any xcodebuild touches it.
  xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$DEVICE_ID" -b >/dev/null 2>&1 || true
  xcrun simctl shutdown "$DEVICE_ID" >/dev/null 2>&1 || true
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
    echo "Rule: every push builds Flex and passes FlexTests, WorkoutFlowUITests, AccountUITests, FlexWatchTests and"
    echo "FlexWatchUITests on the newest runtimes, and the unit tests plus a smoke UI test on the"
    echo "oldest supported ones (CLAUDE.md, How features are built, item 6; CHORE_005)."
    echo "Fix: run 'sh scripts/gates/tests.sh' and fix the failures above. A run that fails before"
    echo "any test starts (\"Simulator device failed to launch\", \"Busy\") is the simulator, not the"
    echo "code: 'xcrun simctl shutdown all' and run again; if it still refuses, erase the device"
    echo "('xcrun simctl list devices | grep \"Flex Gate\"', then 'xcrun simctl erase <udid>')."
    echo "Full log: $log"
    return 1
  fi
  rm -f "$log"
  echo "tests gate passed ($label)"
}

ensure_device "Flex Gate" iOS newest iPhone-17-Pro iPhone-16-Pro iPhone-15-Pro || exit 1
iphone=$DEVICE_ID; iphone_os=$DEVICE_OS
ensure_device "Flex Watch Gate" watchOS newest Apple-Watch-Series-11-46mm Apple-Watch-Series-10-46mm Apple-Watch-Ultra-2-49mm || exit 1
watch=$DEVICE_ID; watch_os=$DEVICE_OS
ensure_device "Flex Gate" iOS "$IOS_FLOOR" iPhone-17-Pro iPhone-16-Pro iPhone-15-Pro || exit 1
iphone_floor=$DEVICE_ID; iphone_floor_os=$DEVICE_OS
ensure_device "Flex Watch Gate" watchOS "$WATCH_FLOOR" Apple-Watch-Series-11-46mm Apple-Watch-Series-10-46mm Apple-Watch-Ultra-2-49mm Apple-Watch-Series-9-45mm || exit 1
watch_floor=$DEVICE_ID; watch_floor_os=$DEVICE_OS
if [ "$1" = "--devices" ]; then exit 0; fi # the resolution alone, for CHORE_004 and CHORE_005's checks

run_tests "iPhone, newest" Flex "platform=iOS Simulator,id=$iphone" \
  -only-testing:FlexTests -only-testing:FlexUITests/WorkoutFlowUITests -only-testing:FlexUITests/AccountUITests || exit 1
run_tests "Apple Watch, newest" FlexWatch "platform=watchOS Simulator,id=$watch" \
  -only-testing:FlexWatchTests -only-testing:FlexWatchUITests || exit 1
# A floor run on the same runtime as the newest run would only repeat it.
if [ "$iphone_floor_os" = "$iphone_os" ]; then
  echo "tests gate: the iOS floor run is the newest run (one iOS runtime installed); skipped"
else
  run_tests "iPhone, iOS $IOS_FLOOR floor" Flex "platform=iOS Simulator,id=$iphone_floor" \
    -only-testing:FlexTests -only-testing:FlexUITests/WorkoutFlowUITests/testTabsLoadWithSampleData || exit 1
fi
if [ "$watch_floor_os" = "$watch_os" ]; then
  echo "tests gate: the watchOS floor run is the newest run (one watchOS runtime installed); skipped"
else
  run_tests "Apple Watch, watchOS $WATCH_FLOOR floor" FlexWatch "platform=watchOS Simulator,id=$watch_floor" \
    -only-testing:FlexWatchTests -only-testing:FlexWatchUITests/WatchRootUITests/testShowsTemplatesAndLastWeightsFromTheSample || exit 1
fi
echo "tests gate passed"
