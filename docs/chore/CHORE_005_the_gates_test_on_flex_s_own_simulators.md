# CHORE_005 — The gates test on Flex's own simulators

**Status:** Approved by the owner 2026-11-10 through the picker: the newest runtime, plus a run on
the floor runtimes (unit tests and one UI smoke test) so the oldest supported iPhone and watch are
tested on every push; the floors stay iOS 18 and watchOS 11. Waits on CHORE_004.

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

- [ ] `scripts/gates/tests.sh` has `ensure_device <name> <device type> <platform>` that finds the
      device by name through CHORE_004's resolver and otherwise creates it on the newest runtime
      that supports the type (`xcrun simctl list runtimes -j`, `supportedDeviceTypes`), and runs
      the iPhone tests on "Flex Gate" and the watch tests on "Flex Watch Gate". `--devices` prints
      them.
- [ ] The floor runs too: "Flex Gate 18" (iPhone 17 Pro type on the oldest installed iOS 18
      runtime, 18.3.1 today) and "Flex Watch Gate 11" (Apple Watch Series 11 (46mm) type on a
      watchOS 11 runtime, downloaded with `xcodebuild -downloadPlatform watchOS -buildVersion`
      if missing) run `FlexTests` and `FlexWatchTests` plus one smoke UI test each
      (`WorkoutFlowUITests/testTabsLoadWithSampleData` and `WatchRootUITests`' first test), so
      the oldest iPhone and watch Flex ships to are built and launched on every push.
- [ ] `README.md` and `CLAUDE.md` name the four gate devices where they name the stock ones;
      `scripts/screenshots.sh` keeps the stock devices, since the store sizes do not change.
- [ ] If the workout-flow UI tests go red on iOS 27.2 the way they did on iOS 26, each failure is
      a bug ticket before this chore is Done; the chore does not pin an older runtime to hide it.

## Testing

- **Unit (shell):** `sh scripts/gates/tests.sh --devices` prints "Flex Gate" on iOS 27.2,
  "Flex Gate 18" on iOS 18.3, "Flex Watch Gate" on watchOS 26.5 and "Flex Watch Gate 11" on
  watchOS 11, creating them on a Mac that lacks them; a second run finds them without creating
  more (`xcrun simctl list devices | grep -c "Flex Gate"` stays at the same count).
- **Gates:** `tests.sh` green on the two devices, then the pre-push hook.
- **UI / integration:** N/A beyond the gate's own run.
