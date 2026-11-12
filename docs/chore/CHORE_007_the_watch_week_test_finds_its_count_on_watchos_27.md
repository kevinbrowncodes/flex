# CHORE_007 — The watch week test finds its count on watchOS 27

**Status:** Done (2026-11-12).

## Summary

On the first run of the gate on the Mac Studio 2022, whose only watchOS runtime is 27.2,
`WatchRootUITests.testShowsTemplatesAndLastWeightsFromTheSample` failed: "No matches found for
'watch-week' IN identifiers" among the static texts. A screenshot of the same launch shows "2/3"
in the top-right corner as designed, so the screen is right; watchOS 27 no longer exposes a
toolbar `Text` as a static text. The test failed the same way on the commit before BUG_003 and
BUG_004, so it was not their doing.

## Why

The tests gate runs on the newest installed runtime, and a red gate blocks every push. The test
asserted the element type, which is an implementation detail; the behaviour the owner sees (the
count and its VoiceOver label) is unchanged.

## Changes

- [x] The test looks for any element with the `watch-week` identifier or the label "2 of 3
      workouts this week", waits for it, and checks the label.

## Testing

- **UI:** the changed test passes on "Flex Watch Gate" (watchOS 27.2); the full tests gate runs
  it with the rest.
