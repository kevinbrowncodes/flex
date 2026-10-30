# BUG_001 — Confirmation dialogs lose their Keep Going button on iOS 26

**Status:** Resolved (2026-10-30). Found by STORY_001's tests gate on its first run.

## Summary

Four decisions in Flex were presented with `confirmationDialog`: Finish Workout?, Discard
Workout?, Delete Template? and Delete Folder?, each with a `.cancel`-role button ("Keep Going",
"Cancel"). On iOS 26 on iPhone, SwiftUI presents these dialogs anchored to the view they are
attached to, in the small popover style the iPad has always used, and in that style it leaves
out the cancel-role button: the only way back is a tap outside the sheet. Two end-to-end tests
that press "Keep Going" and "Cancel" went red, and a person sees the same thing.

## Steps to Reproduce

1. iPhone 17 Pro simulator, iOS 26.x. Launch with `FLEX_DEMO=sample`.
2. Workout tab → Heavy Duty → Heavy Push → Start Workout → Cancel (top left).
3. Look for "Keep Going" under "Discard Workout?". Or: Full Body Workout ⋯ → Delete, look for
   Cancel.

## Expected vs Actual

- Expected: "Discard Workout?" offers "Discard Workout" and "Keep Going"; "Delete Template?"
  offers Delete and Cancel.
- Actual: a 240-point sheet anchored under the Cancel button shows the title, the message and
  the one destructive button. No "Keep Going", no "Cancel". (Accessibility dump of the sheet,
  2026-10-30: one `Button` element, label 'Discard Workout'.)

## Root Cause

`confirmationDialog` lets the OS choose the presentation. iOS 26 chooses the anchored style on
iPhone for dialogs attached to a view in a navigation context, and that style drops the
cancel-role button by design (tap outside dismisses). A destructive choice needs its explicit
"keep going" answer regardless of OS, so the presentation must be one that always shows every
button: an alert.

## Acceptance Criteria

- [x] `ActiveWorkoutView` presents Finish Workout? and Discard Workout? as alerts with the same
      buttons and messages.
- [x] `WorkoutView` presents Delete Template? and Delete Folder? as alerts with the same buttons.
- [x] `WorkoutFlowUITests.testCancelWithLoggedSetsAsksForConfirmation` and
      `testTemplateAndFolderRenameAndDeleteConfirmation` pass on the iPhone 17 Pro (iOS 26)
      simulator, unchanged.

## Resolution

2026-10-30: the four dialogs became `.alert`s. The tests that press the cancel buttons are the
regression cover; no new test.
