# STORY_007 — A workout finished on the watch shows up in History

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); not started, waits on STORY_006. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 7.

As Kevin, I want a workout I finish on the watch to appear in Flex's History on my phone, and
through it on my iPad, whether the phone was in my pocket or in the locker, so that nothing I log
on the wrist is ever lost or typed twice.

## UI Mockup

The finish screen from STORY_006, with the status that this story makes true:

```
 Phone in reach                 Phone in the locker            Later, phone back in reach
┌──────────────┐               ┌──────────────┐               ┌──────────────┐
│ Finished     │               │ Finished     │               │ Flex    3/3  │
│ 45m          │               │ 45m          │               │ HEAVY DUTY   │
│ 7,340 lb     │               │ 7,340 lb     │               │ Heavy Push   │
│              │               │              │               │ 5 exercises  │
│ ✓ Saved to   │               │ ⌚ Will save  │               │   …          │
│   iPhone     │               │   when your  │               │ (the phone   │
│              │               │   iPhone is  │               │  saved it,   │
│ [   Done   ] │               │   nearby     │               │  3/3 now)    │
└──────────────┘               │ [   Done   ] │               └──────────────┘
                               └──────────────┘
```

On the phone nothing new to tap: the workout is in History with its sets, title, date and
duration, and the Profile's week count includes it.

## Acceptance Criteria

- [ ] `WatchSnapshot.finishedKey` names the WatchConnectivity user-info key a `FinishedWorkout`
      travels under (`FlexShared`).
- [ ] The watch's outbox (`JSONFileStore<[FinishedWorkout]>`, from STORY_006) is drained by
      `WatchLink`: every pending finished workout is sent with `transferUserInfo`, which the
      system queues until the phone is reachable; a transfer that completes removes its workout
      from the outbox; on activation, workouts still in the outbox and not among the session's
      outstanding transfers are sent again. The transport is behind a small protocol so the logic
      is tested without a `WCSession`.
- [ ] `WatchState` publishes each finished workout's delivery (`pending`, `delivered`) so the
      finish screen says "Will save when your iPhone is nearby" until the transfer completes and
      "Saved to iPhone" after, including when the completion arrives while the screen is up.
- [ ] `PhoneWatchLink` receives the user info, decodes the `FinishedWorkout` and saves it through
      `LiveWorkoutBridge.save` on the main actor (the live id makes a second delivery a no-op; an
      exercise the phone has never seen becomes a custom exercise). The save posts
      `ModelContext.didSave`, so the watch gets a fresh snapshot (week count, last weights) by the
      path STORY_005 built.
- [ ] A finished workout that cannot be decoded is logged and dropped on the phone, never
      crashes it; a save that throws is logged and the transfer is still considered delivered (the
      watch cannot fix it).
- [ ] No SwiftData model changes; no new rule, no new gate.

## Testing Plan

- **Unit, `FlexTests/PhoneWatchLinkTests.swift`:** `PhoneWatchLink.receive(userInfo:into:)` with a
  real encoded `FinishedWorkout` saves one `Workout` with the live id and its sets; the same user
  info twice saves once; a payload under the wrong key or undecodable saves nothing and returns
  nil; the week count the builder reports goes up by one afterwards.
- **Unit, `FlexWatchTests/OutboxTests.swift`:** with a fake transport, finishing puts one workout in
  the outbox and sends one transfer; completion empties the outbox and marks it delivered; a
  completion with an error keeps it pending; activation re-sends what is pending and not
  outstanding, and nothing that is; the `WatchState` delivery status follows.
- **UI, `FlexWatchUITests/WatchWorkoutUITests.swift` (extended):** after Finish in a `FLEX_DEMO`
  launch (no phone), the screen says "Will save when your iPhone is nearby".
- **By hand:** a real watch finishing a workout with the phone in another room, then the phone
  showing it in History when they meet, is CHORE_003's second step.
- **Gates:** `tests.sh`, `shared-is-portable.sh`, `watch-no-swiftdata.sh`.
