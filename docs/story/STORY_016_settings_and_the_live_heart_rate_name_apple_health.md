# STORY_016 — Settings and the live heart rate name Apple Health

**Status:** Approved by the owner 2026-11-12 through the picker ("Settings + heart rate", with the
mockup below), after App Review rejected 1.1.0 under 2.5.1 (BUG_004).
Done 2026-11-12: built and gated (AccountUITests, WorkoutFlowUITests, the full tests gate on the
Mac Studio 2022); the recording waits on CHORE_006.

As Kevin, I want the iPhone and iPad app to say plainly that Flex works with Apple Health, what it
saves there and what it reads, so that people know and App Review finds it.

## UI Mockup

```
Settings                                   Active workout header, watch linked
┌──────────────────────────────┐          ┌──────────────────────────────────────┐
│ APPLE HEALTH                 │          │ 🕑 12:04   ♥ 128 · Apple Health  ⌚ On watch │
│ ♥ Apple Health               │          └──────────────────────────────────────┘
│ Flex works with Apple Health.│
│ A workout you do with Flex on│
│ Apple Watch is saved to      │
│ Apple Health with your heart │
│ rate and active calories,    │
│ if you allow it. Flex reads  │
│ heart rate only during a     │
│ watch workout and never      │
│ copies Health data into its  │
│ own storage.                 │
│ Open Health ›                │
└──────────────────────────────┘
```

## Acceptance Criteria

- [x] Settings shows an Apple Health section, after Workout, with the wording above; Open Health
      opens the Health app and appears only where Health is available.
- [x] The active workout's heart rate reads "♥ 128 · Apple Health", with the VoiceOver label
      "Heart rate 128, from Apple Health".
- [x] `appstore/asc_meta.json`'s review notes say where both are, and
      `review_info.external_services` names HealthKit and iCloud.

## Testing Plan

- **UI, `FlexUITests/AccountUITests.swift`:** Settings shows the Apple Health section and its
  wording.
- **UI, `FlexUITests/WorkoutFlowUITests.swift`:** with `FLEX_DEMO_WATCH=128` the header shows the
  heart rate with "Apple Health".
- **Unit:** none; the change is wording on two screens, which the UI tests read.
- **Gates:** every gate in `scripts/gates/`.
- **By hand:** the review recording shows the section on a physical iPhone (CHORE_006).
