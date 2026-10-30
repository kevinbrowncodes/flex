# STORY_011 — Weekly progress on the watch face

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); not started, waits on STORY_010. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 11.

As Kevin, I want a complication on my watch face that shows how many workouts I have done this
week against my target and opens Flex when tapped, so that the number I care about is a glance
away and the app is one tap away.

## UI Mockup

```
 Circular                 Corner                    Rectangular
  ╭─────╮                  ╭──╮                    ┌───────────────────┐
  │ 2/3 │  ring 2/3 full    │2/3│ arc 2/3 full      │ Flex              │
  ╰─────╯                  ╰──╯                    │ ◔ 2 of 3 workouts │
                                                   │   this week       │
                                                   └───────────────────┘
  Target met: the ring is full and green. No snapshot yet: "–/3" and an empty ring. Tap: Flex opens.
```

## Acceptance Criteria

- [ ] `Flex/FlexShared/WeekProgress.swift` holds the numbers the face shows: `fraction` (0…1,
      clamped), `label` ("2/3", "–/3" with no snapshot), `isMet`, and `text` ("2 of 3 workouts
      this week"), tested.
- [ ] The watch app writes `workoutsThisWeek` and `weeklyTarget` into the shared container of an
      App Group (`group.kevinbrowncodes.Flex`) every time a snapshot arrives and asks WidgetKit to
      reload, so the extension never reads the snapshot file itself. `FlexWatch` and the extension
      carry the App Groups entitlement.
- [ ] A `FlexWatchWidgets` target (watchOS WidgetKit extension, bundle
      `kevinbrowncodes.Flex.watchkitapp.widgets`, embedded in `FlexWatch` through an "Embed App
      Extensions" phase, written into the project by hand on Wristwide's pattern, compiling
      `FlexShared`) provides one widget, `WeekProgressWidget`, in the accessory circular, corner
      and rectangular families, drawn from `WeekProgress`; a tap opens Flex.
- [ ] The timeline is a single entry refreshed on reload; with nothing in the shared container the
      widget shows the empty state, never a crash.
- [ ] `scripts/gates/tests.sh` builds the extension as part of the `FlexWatch` scheme (no extra
      bundle to test); `README.md` names the target.

## Testing Plan

- **Unit, `FlexTests/WeekProgressTests.swift` and `FlexWatchTests/WeekProgressTests.swift`:**
  fraction and label for 0/3, 2/3, 3/3, 5/3 (clamped, met), a zero target, and no snapshot.
- **Unit, `FlexWatchTests/WatchStateTests.swift` (extended):** receiving a snapshot writes the two
  numbers to the given shared defaults (an injected `UserDefaults` suite in the test).
- **UI:** none; complications are not reachable from XCUITest. The extension builds in the gate.
- **By hand (CHORE_003):** add the complication to a face on a real watch and see 2/3 become 3/3
  after a workout.
- **Gates:** `tests.sh`, `shared-is-portable.sh`, `watch-no-swiftdata.sh` (the extension folder is
  added to its scan).
