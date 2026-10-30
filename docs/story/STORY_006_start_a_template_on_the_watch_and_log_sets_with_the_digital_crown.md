# STORY_006 — Start a template on the watch and log sets with the Digital Crown

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 6.

As Kevin, I want to start a template from my watch, turn the Digital Crown to set the weight or
reps, tap once per set, rest on the wrist timer, and finish, with the phone out of reach, so that
a whole gym session needs nothing but the watch.

## UI Mockup

Template (from STORY_005) gains Start; the workout is one vertical page per exercise plus a
Finish page; the Crown edits whichever of weight and reps is highlighted.

```
 Template               Exercise page             Rest running            Finish page
┌──────────────┐       ┌──────────────┐          ┌──────────────┐        ┌──────────────┐
│ Heavy Push   │       │ 12:41        │          │ ⏳ 1:24  Skip │        │ Heavy Push   │
│ [ ▶ Start ]  │       │ Bench Press  │          │ Bench Press  │        │ 12:41        │
│ Bench Press  │       │  (Barbell)   │          │  (Barbell)   │        │ 6 of 9 sets  │
│  2 sets      │  ──▶  │ Set 1 of 2   │   ──▶    │ Set 2 of 2   │  ──▶   │ 7,340 lb     │
│  last 185×8  │       │ last 185 × 8 │          │ last 205 × 6 │        │ [ ✓ Finish ] │
│ Incline…     │       │ [185] lb  ◀  │ Crown    │ [205] lb  ◀  │        │   Discard    │
│              │       │  8  reps     │          │  6  reps     │        └──────────────┘
└──────────────┘       │ [  ✓ Done  ] │          │ [  ✓ Done  ] │
                       │   + Add Set  │          │   + Add Set  │
                       └──────────────┘          └──────────────┘
                              ◀ = the highlighted value; tap the other to move the Crown
```

After Finish: "Finished · 45m · 7,340 lb" and "Will save when your iPhone is nearby" (STORY_007
makes that true and says "Saved to iPhone" when it has).

## Acceptance Criteria

- [x] `LiveWorkoutSession` moves to `Flex/FlexShared` as the device-neutral core (start, apply,
      persist after every edit, resume, discard, `finish(at:) -> FinishedWorkout?`), with no
      platform import; the phone keeps `finish(into:)` as an extension in `Flex/Flex/Support`.
      Behaviour on the phone is unchanged and its tests stay green.
- [x] The watch holds a `LiveWorkoutSession` over its own `LiveWorkoutStore`, so a workout in
      progress survives the watch app being closed, and `FLEX_DEMO` launches start clean unless
      `FLEX_DEMO_RESUME=1`, as on the phone.
- [x] The template screen gains Start (`watch-start`), which starts
      `LiveWorkout(from: template, restSeconds: snapshot.restSeconds)` and shows the workout.
      While a workout is live, the watch app opens on it, not the home.
- [x] The workout is a vertical `TabView` of pages: one per exercise, then Finish. An exercise
      page shows the running clock, the exercise name, "Set n of N" for the first uncompleted set
      (or the last set when all are done), "last …" from the previous sets, the set's weight
      (`watch-weight`) and reps (`watch-reps`), Done (`watch-done`) and Add Set (`watch-add-set`).
      Tapping weight or reps highlights it; the Digital Crown changes the highlighted value (2.5 lb
      or 1 rep a step, never below 0) through `LiveWorkoutEdit`s, so every turn is persisted.
- [x] Done completes the current set (which starts rest when the default is on), moves to the
      next uncompleted set, and after the last set of the last exercise moves to the Finish page.
      Add Set appends a set copying the current set's weight and reps.
- [x] While rest runs, a bar at the top shows the countdown and Skip (`watch-rest`, `watch-rest-skip`);
      when rest reaches zero the watch plays the success haptic once. Cardio exercises show the
      set's time as text instead of weight and reps, read-only, with Done.
- [x] The Finish page shows the title, the clock, completed over logged sets, total volume, Finish
      (`watch-finish`) and Discard (`watch-discard`, confirmed). Finish keeps the `FinishedWorkout`
      in the watch's outbox (`JSONFileStore<[FinishedWorkout]>`, "finished-workouts.json") for
      STORY_007 to deliver, clears the live workout, and shows "Finished", the duration and volume,
      and "Will save when your iPhone is nearby", with Done back to the home.
- [x] No new rule, no new gate; `watch-no-swiftdata.sh` keeps holding.

## Testing Plan

- **Unit, `FlexTests/LiveWorkoutBridgeTests.swift` (`sessionPersists`, unchanged) and
  `FlexTests/LiveWorkoutTests.swift`:** the shared session still starts, persists, resumes,
  finishes into SwiftData on the phone and discards; `finish(at:)` returns the trimmed finished
  workout and ends the session.
- **Unit, `FlexWatchTests/WatchWorkoutTests.swift`:** a session started from the sample Heavy Push
  template has its sets and rest default; Done on set 1 completes it and starts rest; the "current
  set" after each Done moves forward and lands on the last set when all are done; Add Set copies
  weight and reps; the Crown step helpers clamp at zero and step by 2.5 and 1; `finish(at:)` puts
  one `FinishedWorkout` in the outbox with empty sets dropped and clears the live store.
- **UI, `FlexWatchUITests/WatchWorkoutUITests.swift`:** with `FLEX_DEMO=sample`, open Heavy Push,
  tap Start, see "Set 1 of 2" and `watch-weight` "185", tap Done, see `watch-rest` appear and
  "Set 2 of 2", tap Skip, tap Done, swipe to the Finish page (or reach it by Done), tap Finish, see
  "Finished" and "Will save when your iPhone is nearby". A second test starts, logs, terminates
  and relaunches with `FLEX_DEMO_RESUME=1` to find the workout still on screen.
- **Gates:** `tests.sh`, `shared-is-portable.sh` (the moved session must pass it),
  `watch-no-swiftdata.sh`.
