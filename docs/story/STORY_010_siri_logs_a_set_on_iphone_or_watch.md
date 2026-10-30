# STORY_010 — Siri logs a set on iPhone or Watch

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); not started, waits on STORY_009. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 10.

As Kevin, I want to tell Siri "Log bench press in Flex", answer "135" and "8", and have the set
logged in the workout I am doing (or in a workout Flex starts for me), on the phone or the watch,
so that a set is logged without touching anything when my hands are chalky or full.

## UI Mockup

A Siri conversation, the same on both devices (Siri phrases cannot carry numbers, so the weight
and reps are asked for):

```
 You:   "Log bench press in Flex"
 Siri:  "How much weight?"            ← skipped when said: "Log bench press in Flex, 135 pounds"
 You:   "135"
 Siri:  "How many reps?"
 You:   "8"
 Siri:  "Logged 135 lb × 8 on Bench Press (Barbell)."        ← rest starts, as a tap would

 With no workout running:
 Siri:  "Started Evening Workout and logged 135 lb × 8 on Bench Press (Barbell)."

 "Bench press" matches two exercises:
 Siri:  "Which one?"  ◦ Bench Press (Barbell)  ◦ Bench Press (Dumbbell)   ← the one in the workout first
```

## Acceptance Criteria

- [ ] `Flex/FlexShared/SetLogger.swift` holds the logic, pure and tested: given a catalog exercise
      (name, body part, category, bar type), a weight and reps, a live workout or nil, the rest
      default and now, it returns the edits to apply (start a workout named by time of day when
      there is none; add the exercise when the workout lacks it; fill the first uncompleted set,
      or a new set when every set is done; complete it) and the sentence Siri says.
- [ ] `LogSetIntent` (`AppIntents`) lives once in `Flex/FlexShared` and is built into both apps:
      parameters exercise (`ExerciseEntity`, resolved by a query over the device's catalog), weight
      in lb and reps, each asked for when not said. `FlexShortcuts` (`AppShortcutsProvider`) offers
      "Log \(exercise) in Flex" and "Log a set in Flex". The intent runs the logger against the
      device's `LiveWorkoutSession` (through `AppDependency`), applies the edits, and returns the
      sentence as its dialog. `shared-is-portable.sh` allows `AppIntents` in `FlexShared` for this,
      with the reason in the gate.
- [ ] The catalog is a protocol: the phone resolves exercises from SwiftData (every exercise,
      archived excluded), the watch from the snapshot's exercises; both prefer an exercise already
      in the live workout and let Siri disambiguate between the rest by name.
- [ ] The phone registers the dependencies and the shortcuts at launch; the watch likewise. The
      intent opens no UI and runs in the background (`openAppWhenRun` false).
- [ ] Logging through Siri mirrors like any edit when STORY_009's link is up (nothing extra needed:
      it goes through `LiveWorkoutSession.apply`).
- [ ] No SwiftData model changes; the gate change is the allowed-imports line.

## Testing Plan

- **Unit, `FlexTests/SetLoggerTests.swift`:** each case of the logger: a running workout with the
  exercise and an uncompleted set (fills and completes it, rest starts); every set done (a new set
  is added and completed); the exercise missing (added with one set, filled); no workout (started
  with the time-of-day title, the sentence starts with "Started"); the sentence formats weight and
  reps through `Formatting`; a weight of 0 reads as bodyweight ("8 reps").
- **Unit, `FlexTests/ExerciseCatalogTests.swift`:** the phone catalog excludes archived exercises,
  orders a workout's exercise first, and matches "bench press" against both barbell and dumbbell.
- **Unit, `FlexWatchTests/WatchCatalogTests.swift`:** the watch catalog resolves from the sample
  snapshot the same way.
- **UI:** none; Siri cannot be driven from XCUITest. The intent's phrases are checked by Xcode at
  build time (an invalid `AppShortcut` phrase fails the build).
- **By hand (CHORE_003):** "Log bench press in Flex" on the watch during a real workout.
- **Gates:** `tests.sh`, `shared-is-portable.sh` (with AppIntents allowed), `watch-no-swiftdata.sh`.
