# CHORE_001 — The new-exercise test searches before it looks

**Status:** Done (2026-10-30). Found by STORY_001's tests gate on its first run.

## Summary

`WorkoutFlowUITests.testCreateCustomExerciseRejectsDuplicateNames` saves a custom exercise named
"Bench Press (Barbell) Pause" and then waits for that text in the Exercises list. On the iPhone
17 Pro simulator the row lands just below the fold, and a lazy `List` never creates a row that is
not on screen, so the wait timed out although the exercise was saved. The test now types "Pause"
into the list's search field (`exercise-search`) first, which brings the one row into view.

## Why

The test asserts that the exercise was saved and is listed; where in the list it lands depends
on the screen and on how many exercises the library holds, and is not the point.

## Changes

- [x] After tapping `save-exercise`, tap `exercise-search`, type "Pause", then wait for the row.

## Testing

- **UI:** the changed test itself, green on the iPhone 17 Pro simulator through
  `scripts/gates/tests.sh`.
- **Unit / integration:** N/A, a test-only change.
