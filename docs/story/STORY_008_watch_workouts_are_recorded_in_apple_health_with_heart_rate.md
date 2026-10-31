# STORY_008 — Watch workouts are recorded in Apple Health with heart rate

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day; CHORE_002 publishes the privacy page and answers App Store Connect. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 8.

As Kevin, I want a workout I run from the watch to count in Apple Health, with my heart rate and
calories, and to keep Flex on the screen when my wrist drops, so that lifting counts toward my
rings like any other workout and the app is there when I look back at it mid-set.

## UI Mockup

The exercise page and finish screen from STORY_006, with the Health numbers; the first start asks
once (the system's Health sheet):

```
 First start                  Exercise page                Finish
┌──────────────┐             ┌──────────────┐             ┌──────────────┐
│ Flex would   │             │ 12:41  ♥ 128 │             │ Finished     │
│ like to      │             │ Bench Press  │             │ 45m · 7,340lb│
│ access Health│             │  (Barbell)   │             │ ♥ 131 avg    │
│ ☐ Heart Rate │             │ Set 1 of 2   │             │ 🔥 412 kcal  │
│ ☐ Workouts   │             │ last 185 × 8 │             │ ✓ Saved to   │
│ ☐ Energy     │             │ [185] lb  ◀  │             │   Apple      │
│ [Allow All]  │             │  8  reps     │             │   Health     │
│ [Don't Allow]│             │ [  ✓ Done  ] │             │ [   Done   ] │
└──────────────┘             └──────────────┘             └──────────────┘
                  Declined: the page shows "♥ --", the finish screen no Health lines, logging works.
```

## Acceptance Criteria

- [x] `FlexWatch` and `Flex` gain the HealthKit entitlement (`com.apple.developer.healthkit`,
      no clinical access) in `FlexWatch.entitlements` and `Flex.entitlements`, and both targets
      set `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` through their
      `INFOPLIST_KEY_` settings, in words a reviewer reads: why Flex reads heart rate and energy
      and why it writes workouts.
- [x] `WatchHealthSession` (watch) starts an `HKWorkoutSession` (traditional strength training,
      indoor) with an `HKLiveWorkoutBuilder` when a live workout starts, after asking for
      authorization the first time; it publishes the latest heart rate and active energy, ends the
      session and saves the `HKWorkout` (the Flex title as metadata) when the live workout
      finishes, and discards it when the live workout is discarded. The health store is behind a
      protocol so the controller is tested with a fake.
- [x] Authorization declined, or Health unavailable, changes nothing about logging: the page shows
      "♥ --", the finish screen shows no Health lines, and no session is started.
- [x] The exercise pages show the current heart rate (`watch-heart-rate`); the finish screen shows
      average heart rate and active energy (`watch-health-summary`) and "Saved to Apple Health"
      once the `HKWorkout` is saved.
- [x] The running `HKWorkoutSession` keeps Flex frontmost when the wrist drops, as watchOS does
      for workout apps; nothing else is needed for it.
- [x] `FLEX_DEMO` launches never touch HealthKit (no sheet in UI tests); the page shows "♥ --".
- [x] `scripts/gates/health-usage-strings.sh` fails any target whose entitlements grant HealthKit
      while its build settings lack either usage string, with the rule and the fix in its
      message, self-tested on a planted project fragment.
- [x] The privacy policy on the support site (repo `kevinbrowncodes/flex-support`, the App Store's
      privacy URL) gains a Health section: what is read (heart rate, active energy during a
      workout), what is written (the workout), that it stays on the device and in the user's
      Health data and is never sent to Flex's servers (there are none). Committed in that repo;
      publishing it and the App Store Connect privacy answers are CHORE_002.

## Testing Plan

- **Unit, `FlexWatchTests/WatchHealthSessionTests.swift`:** with a fake health store: starting a
  live workout requests authorization once and starts a session; a heart-rate sample updates the
  published rate; finishing ends the session and saves a workout with the live title and dates;
  discarding discards; authorization denied starts nothing and the rate stays nil; Health
  unavailable starts nothing.
- **UI, `FlexWatchUITests/WatchWorkoutUITests.swift` (extended):** in a `FLEX_DEMO` launch the
  exercise page shows `watch-heart-rate` as "♥ --" and no Health sheet ever appears.
- **Unit (shell):** `health-usage-strings.sh` refuses a planted configuration block with the
  entitlement and one missing string, and passes the real project.
- **By hand:** heart rate on a real watch and the workout in Health is CHORE_003's third step.
- **Gates:** `tests.sh`, `shared-is-portable.sh`, `watch-no-swiftdata.sh`,
  `health-usage-strings.sh` (new).
