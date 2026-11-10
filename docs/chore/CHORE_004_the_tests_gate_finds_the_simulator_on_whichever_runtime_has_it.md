# CHORE_004 — The tests gate finds the simulator on whichever runtime has it

**Status:** Done (2026-11-10). Found by the pre-push hook on the first push after Xcode moved from
27.1 to 27.2; the gate ran green on the iPhone 17 Pro (iOS 26.5) and the Apple Watch Series 11
(46mm) (watchOS 26.5) the same afternoon, once the Mac was free of other sessions' test runs.

## Summary

`scripts/gates/tests.sh` handed xcodebuild a bare device name (`name=iPhone 17 Pro`). xcodebuild
resolves a bare name against the newest installed runtime, and Xcode 27.2 brought iOS 27.2 with no
iPhone 17 Pro on it, so the gate failed with "Unable to find a device matching the provided
destination specifier" before a single test ran, and refused a push of three commits that change
no code. The gate now resolves each name itself to the device on the newest runtime that has it
(today the iPhone 17 Pro on iOS 26.5 and the Apple Watch Series 11 (46mm) on watchOS 26.5) and
passes xcodebuild the device id. `sh scripts/gates/tests.sh --devices` prints the choice and stops.

## Why

A gate that fails on a toolchain update, with the code untouched, teaches everyone to reach for
`--no-verify`. The devices the README names should be found wherever they are installed, and the
message when one is missing should say how to add it.

## Changes

- [x] `scripts/gates/tests.sh` resolves `iPhone 17 Pro` and `Apple Watch Series 11 (46mm)` through
      `xcrun simctl list devices available -j` to the device on the newest runtime that has each,
      and uses `id=` destinations; a missing device fails with the rule and the fix; `--devices`
      prints the two choices and exits 0.
- [x] `README.md` says so under the test commands, and how to run them by hand when xcodebuild
      cannot find the device.
- [x] On a red run the gate prints each failing test's message from the newest `.xcresult`
      (`xcrun xcresulttool get test-results summary`), which `xcodebuild -quiet` hides, and says
      that a run of timeouts while another `xcodebuild test` is on the Mac is a starved simulator,
      not the code. Found on the chore's first run: three other sessions were testing at once and
      all ten workout-flow UI tests timed out waiting for buttons.

## Testing

- **Unit (shell):** `sh scripts/gates/tests.sh --devices` prints the iPhone 17 Pro on iOS 26.5 and
  the Apple Watch Series 11 (46mm) on watchOS 26.5, the devices the README names, and exits 0.
- **Gates:** `scripts/gates/tests.sh` runs green end to end on those devices, then the pre-push
  hook runs every gate on the push.
- **UI / integration:** N/A, a gate-only change; no app code moves.
