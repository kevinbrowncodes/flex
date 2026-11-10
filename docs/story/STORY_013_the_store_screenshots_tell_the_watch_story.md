# STORY_013 — The store screenshots tell the watch story

**Status:** Drafted 2026-11-10 from the owner's picker answers (refresh the phone set with a
watch-first hero shot; Ashton is the lifter in every screenshot); the mockup below approved by the
owner the same day through the picker. STORY_012's upload waits on it. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md)
row 13.

As Kevin, I want the iPhone and iPad screenshots to open on the watch and to show Ashton as the
lifter, so that a shopper searching for a watch workout log sees the wrist in the first two shots
and every name in the set is ours.

## UI Mockup

Shot 1 is new: the active workout 41 minutes in with the watch linked, composed by shotkit in the
same caption-top layout and dark gradient as the rest. The old hero moves to shot 3; the plate
calculator stays at shot 2 because shots 1 and 2 are what search results show.

```
 1  Start on your Apple Watch      2  Know what to load on the bar   3  Log every set in seconds
┌────────────────────────────┐    (unchanged)                       (the 1.0.3 hero, unchanged)
│  Start on your             │
│  **Apple Watch**           │     4  Routines ready in one tap
│  Log sets from your wrist, │     5  Every workout, every PR
│  phone in the locker       │     6  Hit your weekly goal          ← Profile reads "Ashton"
│ ┌────────────────────────┐ │     7  Finish strong, share it
│ │ 9:41          ♥ 128    │ │     8  Hundreds of exercises, plus your own
│ │ Cancel  ⌚ On watch     │ │
│ │ Heavy Push      41:15  │ │    The watch set (`out-watch`) is re-captured by the same run and
│ │ ⏳ Rest 1:27 −15 +15 Skip│ │    stays as it is: no name shows on the watch.
│ │ Bench Press (Barbell)  │ │
│ │ 1  185×8  185  8   ✓   │ │
│ │ 2  205×6  205  6   ○   │ │
│ └────────────────────────┘ │
└────────────────────────────┘
```

## Acceptance Criteria

- [ ] A DEBUG-only demo seam makes `PhoneMirrorHost` report the watch as linked with a heart rate
      from the launch environment (`FLEX_DEMO_WATCH=128`), so the active-workout header shows
      "♥ 128" and "On watch" in a demo launch (`Flex/Flex/Views/Workout/ActiveWorkoutView.swift`
      shows both only when `mirrorHost.isLinked`). `Support/DemoMode.swift` documents the variable.
- [ ] The demo lifter is Ashton everywhere a screenshot can show a name: the default in
      `Support/DemoMode.swift`, the launch helper in `FlexUITests/FlexUITestCase.swift`,
      `FlexWatch/WatchSampleData.swift`, and the tests that assert the name.
- [ ] `FlexUITests/ScreenshotTests.swift` captures `00-watch-hero` (Heavy Push 41 minutes in,
      set 1 done, rest counting, "♥ 128", "On watch") with `FLEX_DEMO_WATCH=128`, and the profile
      capture asserts "Ashton" on screen.
- [ ] `appstore/screenshots/shots.json` gains the hero as shot 1 (caption "Start on your
      **Apple Watch**", subcaption "Log sets from your wrist, phone in the locker"), moves the old
      hero to shot 3, and the eight shots render for `iphone-6.9` and `ipad-13`.
- [ ] `appstore/asc_meta.json`'s `screenshots` map lists the eight stems in order for both slots;
      `appstore/SUBMISSION.md` and `appstore/screenshots/README.md` describe the new set.
- [ ] `scripts/screenshots.sh` regenerates all three sets from the 1.1.0 build and
      `../launch/bin/launch preflight flex` passes on them.

## Testing Plan

- **UI, `FlexUITests/ScreenshotTests.swift`:** each capture asserts the screen it photographs; the
  hero asserts the rest countdown, "128" and "On watch"; the profile asserts "Ashton".
- **Unit, `FlexTests/SupportTests.swift`:** `DemoMode` defaults the name to Ashton, and
  `FLEX_DEMO_WATCH=128` yields a linked mirror host reporting 128 bpm.
  `FlexWatchTests/WatchSmokeTests.swift`: the watch sample snapshot names Ashton.
- **Gates:** `tests.sh` (the unit and UI bundles), then Launch's preflight on the rendered sets
  (counts, sizes, no alpha).
- **By hand:** none; a simulator produces everything here.
