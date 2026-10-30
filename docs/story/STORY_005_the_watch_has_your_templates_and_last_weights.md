# STORY_005 — The watch has your templates and last weights

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); not started, waits on STORY_004. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 5.

As Kevin, I want my watch to carry my template folders, each template's exercises with their
planned sets, and the weight and reps I last did for each exercise, kept fresh by the phone, so
that the watch can start any workout the phone could and show me what I lifted last time, with
the phone left in the locker.

## UI Mockup

The watch home once a snapshot has arrived (the waiting screen from STORY_004 until then), and a
template opened from it. Start arrives in STORY_006; this story is the data and the reading of it.

```
 Home                           Heavy Push
┌──────────────┐               ┌──────────────┐
│ Flex    2/3  │               │ Heavy Push   │
│ HEAVY DUTY   │               │ Bench Press  │
│ Heavy Push   │               │  (Barbell)   │
│ 5 exercises  │               │  2 sets      │
│ Heavy Pull   │  ─ tap ─▶     │  last 185×8  │
│ 4 exercises  │               │ Incline Bench│
│ Heavy Legs   │               │  Press…      │
│ TEMPLATES    │               │  2 sets      │
│ Full Body    │               │  last 155×8  │
└──────────────┘               └──────────────┘
   2/3 = workouts this week / weekly target, from the phone
```

## Acceptance Criteria

- [ ] `Flex/FlexShared/WatchSnapshot.swift` defines `WatchSnapshot` (made at, folders in name
      order with their templates, unfiled templates, workouts this week, the weekly target, the
      rest default, the user's first name) and `SnapshotTemplate` (template id, name, folder name,
      exercises) whose `SnapshotExercise` carries name, body part, category, bar type, the planned
      sets (reps, weight) and the previous workout's sets. All `Codable`, `Equatable`, `Sendable`,
      Foundation only, decoding tolerant of missing keys as STORY_002 set.
- [ ] `LiveWorkout.init(from: SnapshotTemplate, at:restSeconds:)` builds a live workout the way
      `LiveWorkoutBridge.start(from:)` does on the phone (planned sets become sets, one empty set
      when a template has none, previous sets carried), with fresh exercise and set ids every time.
- [ ] The phone builds the snapshot from SwiftData and preferences (`WatchSnapshotBuilder`): this
      week's workouts counted on the user's calendar week, each exercise's previous sets from
      `mostRecentWorkoutExercise(before: now)`, templates ordered as the Workout tab shows them.
- [ ] The phone sends it (`PhoneWatchLink`, a `WCSession` delegate) with
      `updateApplicationContext` when the session activates, when Flex comes to the foreground,
      and after any SwiftData save (debounced one second), and never on a device without
      WatchConnectivity (iPad). A snapshot identical to the last one sent is not re-sent.
- [ ] The watch receives it (`WatchLink`, a `WCSession` delegate), keeps the latest in
      `WatchSnapshotStore` (JSON under Application Support) and in a `WatchState` observable, so a
      relaunched watch app shows the last snapshot with no phone in reach.
- [ ] The watch home lists folders as sections with their templates, unfiled templates under
      "Templates", each with its exercise count, and "2/3" (this week over the target) in the
      toolbar. Tapping a template shows its exercises with set counts and "last 185 × 8" from the
      previous sets, "—" when there is none.
- [ ] `WatchDemoMode` `sample` installs a bundled sample snapshot (the phone's Heavy Duty folder
      and Full Body template, with last weights) so UI tests and screenshots need no phone; `empty`
      installs none.
- [ ] `scripts/gates/watch-no-swiftdata.sh` fails any file under `Flex/FlexWatch` that imports
      SwiftData or CloudKit or names `ModelContainer` or `ModelContext`, with the rule (the phone
      is the only writer, EPIC_001) and the fix (put it in the snapshot) in its message, and
      self-tests on a planted file.

## Testing Plan

- **Unit, `FlexTests/WatchSnapshotTests.swift`:** the builder on the sample data (folders and
  their templates in order, unfiled templates, previous sets for Bench Press from the generated
  history, this week's count on a fixed "now", the weekly target and rest default from
  preferences); a snapshot round-trips through JSON; `LiveWorkout(from:)` copies planned sets,
  gives one empty set to a set-less template, carries previous sets, and never reuses an id across
  two starts; sparse JSON decodes.
- **Unit, `FlexWatchTests/WatchStateTests.swift`:** `WatchSnapshotStore` saves, loads and clears
  in a temporary folder; `WatchState` publishes a received snapshot and the sample snapshot has
  the Heavy Duty folder.
- **UI, `FlexWatchUITests/WatchRootUITests.swift`:** with `FLEX_DEMO=sample`, the home shows
  "Heavy Push" under "Heavy Duty" and "2/3"; tapping Heavy Push shows "Bench Press (Barbell)" and
  "last 185 × 8". With `FLEX_DEMO=empty`, the waiting screen (unchanged test).
- **By hand:** two real devices exchanging a snapshot is CHORE_003's first step; simulators pair
  unreliably and the tests do not rely on WatchConnectivity.
- **Gates:** `tests.sh`, `shared-is-portable.sh`, `watch-no-swiftdata.sh` (new).
