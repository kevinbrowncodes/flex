# STORY_002 — A workout in progress survives Flex being closed

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 2.

As Kevin, I want the workout I am in the middle of to still be there, every set intact, when
Flex is closed by iOS or by me and opened again, so that a phone call or a low-memory kill
mid-session costs me nothing, and so that a watch has one plain value it can read and edit.

## UI Mockup

Nothing new to tap. Open Flex after it was closed mid-workout and the workout is back on top,
on the Workout tab, timer running from the original start:

```
┌─────────────────────────────────┐
│ Cancel                 [Finish] │
│ Heavy Push                   ⋯  │
│ 📅 Oct 30, 2026                 │
│ ⏱ 12:41            ← from the original start
│ ┌─────────────────────────────┐ │
│ │ Bench Press (Barbell)    …  │ │
│ │ Set  Previous   lbs  Reps   │ │
│ │ 1    185 × 8   [205]  [8] ✓ │ │  ← logged before the app closed
│ │ 2    205 × 6   [205]  [6] ○ │ │
│ │        + Add Set            │ │
│ └─────────────────────────────┘ │
│          Add Exercises          │
└─────────────────────────────────┘
```

## Acceptance Criteria

- [x] `Flex/FlexShared/LiveWorkout.swift` defines `LiveWorkout` (id, title, start, template name,
      exercises, last edit time), `LiveExercise` (id, name, body part, category, bar type, sets,
      and the previous workout's sets for the "Previous" column) and `LiveSet` (id, reps, weight,
      time, distance, completed): `Codable`, `Equatable`, `Sendable` value types, Foundation
      only. Set numbers are positions, so a deleted set renumbers the rest by itself.
- [x] Every change is a `LiveWorkoutEdit` (rename, add or remove an exercise, add or delete a
      set, set weight, reps, time, completed) applied by `LiveWorkout.apply(_:at:)`. Adding an
      exercise or a set whose id is already present does nothing, and an edit naming an unknown
      id does nothing, so the same edit can arrive twice or late without harm.
- [x] `LiveWorkout.finished(at:)` returns a `FinishedWorkout`: the end time, and the workout with
      empty sets dropped and exercises with no logged set dropped. The default title by time of
      day moves here (`LiveWorkout.defaultTitle(for:)`); `Formatting` and `BarType` move to
      `Flex/FlexShared` unchanged, and `ExerciseName.normalized` holds the one name key
      `ExerciseLibrary` already merges on.
- [x] `LiveWorkoutStore` saves the live workout as JSON under Application Support after every
      edit and loads it at launch; a file that will not decode is treated as no workout. The
      `FlexShared` folder is a folder-synchronized group compiled into the Flex app (and later the
      watch), not a framework.
- [x] `LiveWorkoutSession` (`@Observable`, in the environment) holds the live workout, applies
      edits, persists, and finishes or discards. `ActiveWorkoutView`, `WorkoutView` and a new
      `LiveExerciseSetView` run on it; nothing in the active workout is a SwiftData model until
      Finish. `EditWorkoutView` keeps its scratch-context editing of saved workouts through the
      same set table (`ExerciseSetTable`), so both screens look and behave as they do today.
      Every accessibility identifier the UI tests use is unchanged.
- [x] Finish saves through `LiveWorkoutBridge.save(_:into:)`: the `Workout` takes the live
      workout's id, each exercise is matched by `ExerciseName.normalized` against every
      exercise (archived included) or created as a custom exercise, sets are renumbered, and a
      finished workout saved twice is saved once. A failed save shows "Couldn't Save Workout" and
      keeps the live workout.
- [x] Starting a workout copies the template's sets and each exercise's most recent earlier
      performance into the live workout (`LiveWorkoutBridge.start(from:at:)`), so the "Previous"
      column and PR counting work as before. The `FLEX_DEMO_WORKOUT_OFFSET` screenshot hook still
      moves the start time.
- [x] On launch with a live workout saved, Flex opens on the Workout tab with the workout on top.
      In demo mode (`FLEX_DEMO`) the saved workout is cleared at launch unless
      `FLEX_DEMO_RESUME=1`, so UI tests start clean and one of them can prove the resume.
- [x] No SwiftData model changes, so no CloudKit schema deploy.

## Testing Plan

- **Unit, `FlexTests/LiveWorkoutTests.swift`:** each edit's effect on the value (rename, add and
  remove an exercise, add and delete a set with renumbering, weight, reps, time, completed), a
  repeated add and an unknown id doing nothing, `finished(at:)` dropping empty sets and empty
  exercises and keeping completed flags, the default title by hour, a JSON round trip through
  `LiveWorkoutStore` in a temporary folder, and decoding older JSON that lacks optional keys.
- **Unit, `FlexTests/LiveWorkoutBridgeTests.swift`:** starting from the sample "Heavy Push"
  template copies its sets and fills previous sets from history; saving creates one `Workout`
  with the live id, the exercises in order, renumbered sets and completed flags; saving the same
  finished workout again returns the existing one; an unknown name becomes a custom exercise; an
  archived exercise is matched, not duplicated.
- **UI, `FlexUITests/WorkoutFlowUITests.swift`:** `testWorkoutInProgressSurvivesRelaunch` starts
  Heavy Push, sets bench set 1 to 205 and ticks it, terminates the app, relaunches with
  `FLEX_DEMO_RESUME=1` on the Profile tab, and sees the workout back with 205 on set 1. Every
  existing workout-flow test stays green, which covers the unchanged halves (template prefill,
  Previous column, plate calculator, finish and PR, cancel, empty workout, edit saved workout).
- **Gates:** `tests.sh`; no new rule in this story, so no new gate.
