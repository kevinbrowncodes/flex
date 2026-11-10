# CHORE_005 — The gates test on Flex's own simulators

**Status:** Done (2026-11-10). Approved by the owner the same day through the picker: the newest
runtime, plus a run on the floor runtimes (unit tests and one UI smoke test) so the oldest
supported iPhone and watch are tested on every push; the floors stay iOS 18 and watchOS 11. Built
after CHORE_004; green on all four devices by 16:58 (iOS 27.2: 79 unit and 13 UI tests; watchOS
26.5: 31; iOS 18.3: 80; the watch floor skipped as a repeat, see below).

## Summary

CHORE_004's first run on 2026-11-10 shared the Mac with three other sessions' `xcodebuild test`
runs; one of them (ShortOrderCook's watch tests) was installing onto the very Apple Watch Series
11 (46mm) simulator Flex's gate uses, and all ten workout-flow UI tests timed out. PipingDatabase
avoids half of that with a device of its own ("PipeBase Gate"). Flex's gate will create "Flex
Gate" (the iPhone 17 Pro device type on the newest iOS runtime that supports it, iOS 27.2 today)
and "Flex Watch Gate" (the Apple Watch Series 11 (46mm) type on the newest watchOS runtime, 26.5
today) when they are missing, and test on those. CPU contention remains; the gate's message
already says what a run of timeouts means.

## Why

Two repos installing onto one simulator at once is a collision that no amount of waiting fixes
cleanly; a device per repo removes it. Naming the devices by role also makes `xcrun simctl list`
say which session owns what.

## Changes

- [x] `scripts/gates/tests.sh` has `ensure_device <name> <device type> <platform>` that finds the
      device by name through CHORE_004's resolver and otherwise creates it on the newest runtime
      that supports the type (`xcrun simctl list runtimes -j`, `supportedDeviceTypes`), and runs
      the iPhone tests on "Flex Gate" and the watch tests on "Flex Watch Gate". `--devices` prints
      them.
- [x] The floor runs too: "Flex Gate 18" (iPhone 17 Pro type on the oldest installed iOS 18
      runtime, 18.3.1 today) and "Flex Watch Gate 11" (Apple Watch Series 11 (46mm) type on a
      watchOS 11 runtime, downloaded with `xcodebuild -downloadPlatform watchOS -buildVersion`
      if missing) run `FlexTests` and `FlexWatchTests` plus one smoke UI test each
      (`WorkoutFlowUITests/testTabsLoadWithSampleData` and `WatchRootUITests`' first test), so
      the oldest iPhone and watch Flex ships to are built and launched on every push.
- [x] `README.md` and `CLAUDE.md` name the four gate devices where they name the stock ones;
      `scripts/screenshots.sh` keeps the stock devices, since the store sizes do not change.
- [x] If the workout-flow UI tests go red on iOS 27.2 the way they did on iOS 26, each failure is
      a bug ticket before this chore is Done; the chore does not pin an older runtime to hide it.
      They went green: 13 of 13 on iOS 27.2, no bug to file.

Corrected while building (2026-11-10): the floor devices cannot always be the same type as the
newest ones. The iOS 18.3.1 runtime predates the iPhone 17 and supports the iPhone 16 Pro at most,
so each gate device takes the first type its runtime supports from a preference list (iPhone 17
Pro, 16 Pro, 15 Pro; Apple Watch Series 11 (46mm), Series 10 (46mm), Ultra 2, Series 9), and the
floor runs happen on whichever that is. The floor runtimes are the oldest installed of the floor's
major version; a missing one is downloaded with `xcodebuild -downloadPlatform` on first use.

Also found (2026-11-10): Apple offers no watchOS 11 simulator runtime for Xcode 27.2 at all
(`xcodebuild -downloadPlatform watchOS -buildVersion 11.0` through `11.6` each answer "not
available for download"; iOS 18.5 likewise), and only watchOS 26.5 is installed. So the watch
floor falls back to the oldest installed runtime as "Flex Watch Gate 26", the gate says so on
every run, and because that is the same runtime as the newest run it skips the repeat. The real
watchOS 11 floor is covered by hand on a device (CHORE_003) until Apple offers the runtime again
or the floor moves. The iOS floor is real: the iOS 18.3.1 runtime from an earlier Xcode is still
installed, and "Flex Gate 18" runs on it.

Also found: a freshly created device's first test run races its first boot. On the new iOS 27.2
device the test runner died mid-suite ("Critical process xctest crashed") and every later test
failed in a second; on the new watch device the runner asked for an app the watch did not know
yet ("Unknown application display identifier"). Both passed on a plain rerun (13 of 13 on iOS
27.2; the watch after a shutdown). The gate now boots a device it has just created to completion
and shuts it down again before any xcodebuild touches it.

## Testing

- **Unit (shell):** `sh scripts/gates/tests.sh --devices` prints "Flex Gate" on iOS 27.2,
  "Flex Gate 18" on iOS 18.3, "Flex Watch Gate" on watchOS 26.5 and "Flex Watch Gate 11" on
  watchOS 11, creating them on a Mac that lacks them; a second run finds them without creating
  more (`xcrun simctl list devices | grep -c "Flex Gate"` stays at the same count).
- **Gates:** `tests.sh` green on the two devices, then the pre-push hook.
- **UI / integration:** N/A beyond the gate's own run.
