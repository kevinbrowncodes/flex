# STORY_012 — Flex for Apple Watch ships to the App Store

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day up to the upload: 1.1.0 build 10 is prepared, the watch screenshots captured and gated, the metadata written. The upload (the one open box) waits on CHORE_002 and CHORE_003. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 12.

As Kevin, I want Flex 1.1.0 with the watch app uploaded to App Store Connect with watch
screenshots and release notes, so that the epic ends on the store and not on a branch.

## UI Mockup

The watch screenshots the store shows (Apple Watch Series 11 46mm, 416 × 496), captured by the
same pipeline as the phone's:

```
 01 Home            02 Logging          03 Rest             04 Finished
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Flex    2/3  │   │ 12:41  ♥ 128 │   │ 12:41 ⏳1:24  │   │ ✓ Finished   │
│ HEAVY DUTY   │   │ Bench Press  │   │ Bench Press  │   │ 45m · 7,340lb│
│ Heavy Push   │   │ Set 1 of 2   │   │ Set 2 of 2   │   │ ♥ 131 avg    │
│ Heavy Pull   │   │ [185] lb  ◀  │   │ [205] lb  ◀  │   │ ✓ Saved to   │
│ Heavy Legs   │   │  8  reps     │   │  6  reps     │   │   iPhone     │
└──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
```

## Acceptance Criteria

- [x] `FlexWatchUITests/WatchScreenshotTests.swift` captures the four screens above in a
      `FLEX_DEMO=sample` launch into `FLEX_SCREENSHOT_DIR`, the way `ScreenshotTests` does on the
      phone; `scripts/screenshots.sh` runs them on the Apple Watch Series 11 (46mm) simulator and
      writes `appstore/screenshots/out-watch/*.png` at 416 × 496 (corrected while building from
      `out/watch/`: shotkit's verify knows no watch device and would call that folder the wrong size);
      `appstore/SUBMISSION.md` and the screenshots README list them.
- [x] `scripts/gates/watch-screenshots.sh` fails when `appstore/screenshots/out-watch/` is missing
      or holds a PNG that is not 416 × 496 or 410 × 502 (the two sizes App Store Connect takes for
      current watches), with the rule and the fix in its message.
- [x] `MARKETING_VERSION` is 1.1.0 and `CURRENT_PROJECT_VERSION` 10 in every target;
      `appstore/asc_meta.json` carries the version and a `whats_new` that names the watch app, the
      rest timer, Siri and Apple Health; the App Store description gains a line on the watch.
- [x] `README.md`'s release section says the watch screenshots are part of a release, and that
      the HealthKit entitlement means App Review may ask for a demo of the Health flow.
- [ ] The build is uploaded with Launch, formerly ascpilot (`../launch/bin/launch release
      flex`) only after CHORE_002 (the privacy answers and page) and
      CHORE_003 (a real gym session) are Done, and the upload's result (version, build number,
      processing state) is written into this story's Status line.
- [x] No SwiftData model changes in this epic, so no CloudKit schema deploy before release; the
      story says so where the release steps would otherwise ask for one.

## Testing Plan

- **UI, `FlexWatchUITests/WatchScreenshotTests.swift`:** the captures themselves; each asserts
  the screen it photographs (home shows Heavy Push, logging shows Set 1 of 2, rest shows the
  countdown, finished shows the status line) so a broken screen cannot ship as a picture.
- **Unit (shell):** `watch-screenshots.sh` refuses a planted PNG of the wrong size and passes the
  rendered set.
- **Gates:** every gate in `scripts/gates/`, green before the upload.

2026-11-10: the upload also waits on STORY_013 (the refreshed screenshots, Ashton as the demo
lifter) and STORY_014 (the iPhone app preview), so Launch uploads the new sets and the video with
the build. The subtitle (33 → 25 characters) and promotional text (204 → 140) were shortened the
same day to fit App Store Connect's limits of 30 and 170, which Launch's preflight enforces.

2026-11-10, 17:30: the owner moved CHORE_003 (the gym session) to after publication and asked
Claude to do the rest: the Launch exemption, CHORE_002 (the privacy page confirmed by fetching
it; the App Privacy answers in App Store Connect through the owner's browser session) and the
release. The upload box above now waits on CHORE_002 only.
