# STORY_003 — A rest timer counts down between sets

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 3.

As Kevin, I want ticking a set to start a rest countdown I can see, nudge and skip, so that I rest
the same every time without a second app, and so that the watch, when it comes, can tap my wrist
when rest is over from the very same timer.

## UI Mockup

The active workout's header, after a set is ticked (Rest default 1:30, from Settings):

```
┌─────────────────────────────────┐
│ Cancel                 [Finish] │
│ Heavy Push                   ⋯  │
│ 📅 Oct 30, 2026                 │
│ ⏱ 12:41                         │
│ ┌─────────────────────────────┐ │
│ │ ⏳ Rest   1:24              │ │  ← counts down each second
│ │   [ −15s ]  [ +15s ] [Skip] │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Bench Press (Barbell)    …  │ │
│ │ 1    185 × 8   [205]  [8] ✓ │ │
```

At 0:00 the card disappears with a success haptic. Settings ▸ Workout:

```
│ Workout                          │
│   Rest Timer            1:30  ›  │   Off · 0:30 · 0:45 · 1:00 · 1:30 · 2:00 · 2:30 · 3:00 · 4:00 · 5:00
```

## Acceptance Criteria

- [x] `LiveWorkout` gains `restSeconds` (the default for this workout, copied from Settings when it
      starts; 0 means off) and `rest: LiveRest?` (`startedAt`, `endsAt`, the set that started
      it). Both are in `FlexShared`, `Codable` with the missing-key tolerance STORY_002 set, so
      the watch inherits the timer with the workout.
- [x] `apply(.setCompleted(setID, true), at: date)` starts rest from `date` for `restSeconds`
      when that is above zero, replacing any rest running; `apply(.setCompleted(setID, false))`
      cancels a rest that set started. New edits: `.setRestSeconds(_:)`, `.adjustRest(by:)` (never
      below the moment of the edit) and `.skipRest`. `restRemaining(at:)` is the seconds left,
      nil once over or when none is running.
- [x] `PreferencesManager.restSeconds` (iCloud key-value store, default 90) and a "Rest Timer"
      row in Settings under a new Workout section, choosing from Off, 0:30, 0:45, 1:00, 1:30,
      2:00, 2:30, 3:00, 4:00, 5:00. `LiveWorkoutBridge.start(from:at:restSeconds:)` copies it in.
- [x] The active workout header shows a rest card (`rest-timer`, counting down each second,
      `rest-minus`, `rest-plus`, `rest-skip`) while rest is running, and nothing when it is not.
      Reaching 0:00 plays a success haptic once and removes the card. The card is in
      `ActiveWorkoutView` and reads the one timer in the live workout, so a watch showing the same
      workout shows the same countdown (STORY_009).
- [x] The timer is wall-clock (`endsAt`), so Flex closed and reopened, or backgrounded, shows the
      true remaining time, and a rest that ended while away shows nothing.
- [x] No SwiftData model changes.

## Testing Plan

- **Unit, `FlexTests/LiveWorkoutTests.swift` (extended):** completing a set starts rest ending
  `restSeconds` later and names the set; completing another set restarts it; un-completing the
  starting set cancels it, un-completing a different set leaves it; `restSeconds == 0` starts
  nothing; `.adjustRest(by:)` moves `endsAt` and never into the past; `.skipRest` clears it;
  `restRemaining(at:)` counts down to nil; the sparse-JSON test still decodes with no rest keys.
- **Unit, `FlexTests/LiveWorkoutTests.swift` (`restTimerDefaults`):** the Settings options run
  Off to 5:00, their labels, and `RestTimer.seconds(stored:)` reads 90 for nothing stored, 0 for a
  stored Off, and a stored value as is. (Corrected while building: `PreferencesManager` talks to
  the real iCloud key-value store and cannot be fed a test store, so the pure read in `RestTimer`
  is what is tested; the manager calls it and the Settings picker drives it.)
- **UI, `FlexUITests/WorkoutFlowUITests.swift`:** `testTickingASetStartsRestYouCanSkip` ticks a
  set, sees `rest-timer` showing a value at or under 1:30, taps `rest-plus` and sees it above
  1:30, taps `rest-skip` and sees the card gone. The existing finish test ticks sets and keeps
  passing with the card present.
- **Gates:** `tests.sh`; no new rule, no new gate.
