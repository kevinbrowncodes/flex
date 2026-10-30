# STORY_004 — Flex installs on Apple Watch

**Status:** Approved by the owner 2026-10-30 (with the epic, "proceed to completion"); built by Fable the same day. [EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 4.

As Kevin, I want Flex to come with a watch app that installs beside it, builds the shared workout
code, and runs under the same demo hook and gates as the phone, so that every later watch story
adds a screen, not scaffolding.

## UI Mockup

The whole watch app in this story, until STORY_005 sends it something to show:

```
┌──────────────┐
│    Flex      │
│              │
│   ⌚ → 📱     │
│ Open Flex on │
│ your iPhone  │
│ to get       │
│ started      │
└──────────────┘
```

## Acceptance Criteria

- [x] `Flex/Flex.xcodeproj` gains three targets written by hand on the pattern of Wristwide's
      project: `FlexWatch` (watchOS app, bundle `kevinbrowncodes.Flex.watchkitapp`, companion
      `kevinbrowncodes.Flex`, runs independently of the companion, watchOS 11.0, device family
      4, display name Flex, version and build numbers matching the iOS app), `FlexWatchTests`
      (unit, hosted by FlexWatch) and `FlexWatchUITests` (UI, targeting FlexWatch). The iOS app
      embeds the watch app through an "Embed Watch Content" phase into
      `$(CONTENTS_FOLDER_PATH)/Watch`, so one install puts Flex on the watch.
- [x] `Flex/FlexWatch`, `Flex/FlexWatchTests` and `Flex/FlexWatchUITests` are
      folder-synchronized groups; `Flex/FlexShared` is compiled into `FlexWatch` as it is into
      `Flex`. A shared `FlexWatch` scheme builds and tests the watch targets from the command
      line.
- [x] The watch app (`FlexWatchApp`, `WatchRootView`) shows the Flex icon and "Open Flex on your
      iPhone to get started" until a snapshot arrives (STORY_005). Its icon is the existing
      1024-pixel Flex icon in a watchOS single-size app icon set.
- [x] `WatchDemoMode` reads `FLEX_DEMO` (and later `FLEX_DEMO_RESUME`) on the watch the way
      `DemoMode` does on the phone, compiled out of Release, so watch UI tests and screenshots
      launch into known state without a phone.
- [x] `scripts/gates/shared-is-portable.sh` fails any file under `Flex/FlexShared` that imports
      anything but Foundation or Observation (no UIKit, SwiftUI, WatchKit, SwiftData, CloudKit,
      HealthKit), with the rule and the fix in its message.
- [x] `scripts/gates/tests.sh` also runs `FlexWatchTests` and `FlexWatchUITests` on an Apple Watch
      simulator, naming red tests the same way; `README.md` lists the watch simulator and the
      commands.

## Testing Plan

- **Unit, `FlexWatchTests/WatchSmokeTests.swift`:** the shared `LiveWorkout` applies an edit on
  watchOS (proves `FlexShared` builds and runs in the watch module); `WatchDemoMode` reads its
  environment. (Built: the parsing moved into `FlexShared/DemoLaunch.swift` so the phone's
  `DemoMode` and the watch's `WatchDemoMode` read `FLEX_DEMO` and `FLEX_DEMO_RESUME` the same way.)
- **UI, `FlexWatchUITests/WatchRootUITests.swift`:** launching with `FLEX_DEMO=empty` shows
  "Open Flex on your iPhone to get started".
- **Unit (shell):** `shared-is-portable.sh` carries a planted file importing SwiftData that it
  must refuse, and passes the real folder.
- **Gates:** `tests.sh` (now four test bundles), `shared-is-portable.sh`.

## Notes

- Target ids follow the project's existing `F1E00001000000000000A0NN` scheme. The watch app has
  no `Info.plist` keys beyond what `GENERATE_INFOPLIST_FILE` and the `INFOPLIST_KEY_WK*`
  settings write.
- HealthKit, WatchConnectivity and the complication are not in this story; each arrives with its
  own entitlement or extension in STORY_005, STORY_008 and STORY_011.
