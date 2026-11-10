# STORY_014 — An iPhone app preview shows a set logged from the wrist

**Status:** Drafted 2026-11-10 after the owner asked for a video. The App Store takes no preview
for Apple Watch and no people or devices on camera (Apple's app preview specifications list
iPhone, iPad, Mac, Apple TV and Apple Vision Pro; the API's preview types have no watch value), so
the video is an iPhone preview of the phone's screen with text overlays. The storyboard was
approved by the owner the same day through the picker; built after STORY_013. Done 2026-11-10:
`appstore/preview/iphone-6.9.mp4`, 25.3 s, 886 × 1920, H.264 30 fps, the gate green. STORY_012's
upload waits on it.
[EPIC_001](../epic/EPIC_001_flex_on_apple_watch.md) row 14.

As Kevin, I want a twenty-second app preview in the iPhone 6.9" slot that shows a workout with the
watch linked, a set completing from the wrist, the rest timer and the finish, so that a shopper who
plays the video sees what the watch adds before reading a word.

## UI Mockup

The storyboard. Every frame is the app's own screen in demo mode; the overlays are text in the
screenshot caption style (white, accent on the key words, top third), which Apple allows.

```
 time     on screen                                            overlay
 0–3 s    Workout tab, Heavy Push tapped, the workout opens     Flex, now on **Apple Watch**
 3–8 s    header shows ♥ 128 · On watch; set 1 ticks            Log sets **from your wrist**
 8–13 s   rest card counts 1:30 → 1:25, +15 and Skip visible     Rest on a **wrist-tap timer**
13–17 s   set 2 ticks, Finish, "Great Job!" with the PR          Finish with your **phone in the locker**
17–20 s   History shows the workout at the top                   Or just say **"Log bench press in Flex"**
```

Portrait, 886 × 1920 (Apple's size for the 6.9" group), H.264, 30 fps, silent, poster frame at
5 s (the ♥ 128 · On watch header). No iPad preview; Apple makes it optional and the iPad set
keeps the screenshots alone.

Corrected while building (2026-11-10): the History beat is gone. Finishing, closing the summary
and loading History took fourteen seconds on a busy Mac and ran the clip to 31 s, past Apple's
30. The clip now ends on the "Great Job!" summary, with the last overlay ("Or just say…") over
its final seconds, and the clip begins a second before the workout opens rather than on the
Workout tab, so the tab-and-folder taps are not in it.

## Acceptance Criteria

- [x] `FlexUITests/PreviewTests.swift` drives the storyboard in `FLEX_DEMO=sample` with
      `FLEX_DEMO_WATCH=128` (STORY_013) at a human pace, asserting each state before it pauses, and
      skips itself unless `FLEX_PREVIEW=1` so `tests.sh` never runs it.
- [x] `scripts/preview.sh` boots the iPhone 17 Pro Max simulator, records it with
      `xcrun simctl io <udid> recordVideo --codec h264` around that test, then with ffmpeg scales
      the capture to 886 × 1920, burns the five overlays at the times above, caps 30 fps, and
      writes `appstore/preview/iphone-6.9.mp4` of 15 to 30 seconds.
- [x] `appstore/asc_meta.json` gains `"previews": {"IPHONE_67": {"file": "preview/iphone-6.9.mp4",
      "poster": "00:00:05:00"}}`, which `launch release flex` uploads after the screenshots.
- [x] `scripts/gates/app-preview.sh` fails when `appstore/preview/iphone-6.9.mp4` is missing or,
      by ffprobe, is not 886 × 1920, not H.264, over 30 fps, or outside 15 to 30 seconds, with the
      rule and the fix in its message; `README.md` lists the gate and the preview in the release
      steps.

## Testing Plan

- **UI, `FlexUITests/PreviewTests.swift`:** the scripted flow asserts every state it shows (the
  linked header, the countdown, the summary's PR line, the History row), so a broken screen cannot
  be filmed.
- **Unit (shell):** `app-preview.sh` refuses a planted video of the wrong size and length and
  passes the rendered one.
- **Gates:** every gate in `scripts/gates/`, plus Launch's preflight, which checks the preview
  file exists.
- **By hand:** none that a simulator cannot do; the simulator records its own screen.
