# STORY_009 — Phone and watch show the same workout live

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day; two real devices prove it in CHORE_003. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 9.

As Kevin, I want a workout I start on either device to be on both, with every set I tick or
weight I change on one showing on the other within a second, the rest timer tapping my wrist
while the phone shows the countdown, and Finish on either ending both, so that the phone on the
bench and the watch on my wrist are one workout, not two.

## UI Mockup

```
 Phone (ActiveWorkoutView)                  Watch (WatchWorkoutView)
┌─────────────────────────────────┐        ┌──────────────┐
│ Cancel                 [Finish] │        │ 12:41  ♥ 128 │
│ Heavy Push                   ⋯  │        │ Bench Press  │
│ ⏱ 12:41   ♥ 128   ⌚ On watch   │ ◀────▶ │  (Barbell)   │
│ ┌─────────────────────────────┐ │  live  │ Set 2 of 2   │
│ │ ⏳ Rest 1:24  −15s +15s Skip│ │        │ ⏳ 1:24  Skip │
│ └─────────────────────────────┘ │        │ [205] lb  ◀  │
│ Bench Press (Barbell)           │        │  6  reps     │
│ 1  185 × 8   [185]  [8]  ✓      │        │ [  ✓ Done  ] │
│ 2  205 × 6   [205]  [6]  ○      │        └──────────────┘
└─────────────────────────────────┘
  Tick set 2 on either side: both show ✓ and both start the same rest. Finish on either: both finish.
  Link lost: each keeps going on its own; the finished workout reaches History through STORY_007.
```

## Acceptance Criteria

- [x] `Flex/FlexShared/WorkoutMirror.swift` defines the messages the two devices exchange over
      the HealthKit mirrored workout session's data channel: `.hello` (a side joined), `.state(LiveWorkout)`
      (the whole workout, the watch's copy), `.edit(LiveWorkoutEdit, at: Date)`, `.vitals(heartRate:, activeEnergy:)`,
      `.finish(at: Date)` and `.discard`, `Codable` through `FlexJSON`. The watch is the source of
      truth while mirrored: it applies every edit (its own and the phone's) and answers with
      `.state`; the phone applies its own edit at once for responsiveness and adopts each `.state`
      whose `updatedAt` is not older than its own. A `MirrorPeer` holds this logic over a
      `MirrorTransport` protocol, so it is tested with two fakes wired together.
- [x] Starting on the watch (STORY_006) begins mirroring to the phone
      (`HKWorkoutSession.startMirroringToCompanionDevice`); the phone's `PhoneWatchLink` installs
      `HKHealthStore.workoutSessionMirroringStartHandler`, takes the mirrored session, sends
      `.hello`, receives `.state`, and the phone's `LiveWorkoutSession` starts with it, so
      `ActiveWorkoutView` comes up on the phone by itself.
- [x] Starting on the phone (`WorkoutView`) calls `HKHealthStore.startWatchApp(toHandle:)` with a
      strength-training configuration; the watch app handles it (`WKApplicationDelegateAdaptor`,
      `handle(_ workoutConfiguration:)`), starts its Health session (STORY_008) mirroring to the
      phone, sends `.hello`, and the phone answers `.state` with its workout, which the watch adopts.
      With no watch paired or the watch app not installed, the phone works as today.
- [x] Every `LiveWorkoutSession.apply` on either side sends `.edit`; the rest timer is part of the
      workout, so one `LiveRest` runs on both: the watch taps when it ends (STORY_006), the phone
      shows the countdown (STORY_003). Finish on either sends `.finish`: the watch ends its Health
      session and saves the `HKWorkout` (STORY_008), the phone saves the `Workout`
      (`LiveWorkoutBridge.save`, idempotent) and both sessions end. Discard on either discards both.
- [x] The phone shows the watch's current heart rate beside the clock (`live-heart-rate`) and
      "On watch" while mirrored; the watch shows nothing new.
- [x] If the mirrored session ends unexpectedly (out of range, the watch app killed), each side
      keeps its own copy and goes on; the watch's finished workout reaches the phone through the
      STORY_007 outbox, and the phone's `LiveWorkoutBridge.save` makes a double arrival a no-op.
- [x] No SwiftData model changes; no new rule, no new gate.

## Testing Plan

- **Unit, `FlexTests/WorkoutMirrorTests.swift`:** two `MirrorPeer`s over fake transports: the
  phone's hello gets the watch's state; an edit on the phone reaches the watch and comes back as a
  state the phone adopts; an edit on the watch reaches the phone; concurrent edits to two
  different sets both survive; concurrent edits to the same field end with the watch's answer on
  both sides; a stale state (older `updatedAt`) is not adopted; finish on either ends both and
  yields one `FinishedWorkout` with the same id on both; messages round-trip through JSON.
- **Unit, `FlexWatchTests/WatchMirrorTests.swift`:** the watch peer applies a phone edit to the
  live session and answers with state; `.finish` ends the Health session (fake) and the live
  session.
- **UI:** none new; simulators cannot mirror a HealthKit session. The phone's existing flows and
  the watch's STORY_006 flows stay green with mirroring code present but no peer.
- **By hand (CHORE_003):** start on the watch and see it on the phone; tick a set on the phone and
  see it on the watch; walk out of range, log two sets, come back; finish on the phone.
- **Gates:** `tests.sh`, `shared-is-portable.sh`, `watch-no-swiftdata.sh`, `health-usage-strings.sh`.
