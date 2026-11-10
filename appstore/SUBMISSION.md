# Flex — App Store submission notes

## URLs

| Field | Value |
|---|---|
| Support URL | https://kevinbrowncodes.github.io/flex-support/ |
| Privacy Policy URL | https://kevinbrowncodes.github.io/flex-support/privacy |
| Copyright | © 2026 Ashton Krstolic & Kevin Brown |

Source for both pages: https://github.com/kevinbrowncodes/flex-support
(the previous listing URLs on flexkeyapp.com returned 404 on 2026-09-05 and were replaced.)

## Release automation

`appstore/asc_meta.json` drives `../launch/bin/launch release flex` (Launch, formerly ascpilot: archive, upload, create
version, metadata, screenshots, attach build, submit). Version 1.0.3 / build 9 was
uploaded this way on 2026-09-05.

## Description — suggested closing paragraph

> Flex is designed and built by two fitness freaks, Ashton Krstolic and Kevin Brown.
> Every feature exists because we needed it at the rack. Questions or ideas?
> Open an issue on our support page — we read every one.

## Screenshots

Upload from `appstore/screenshots/out/` in numeric order. Shots 1–2 are the ones
that appear in App Store search results. The demo lifter in every capture is Ashton (STORY_013).

| # | Screen | Caption | Subcaption |
|---|---|---|---|
| 1 | Active workout 41 minutes in with the watch linked: ♥ 128, On watch, rest counting (STORY_013) | Start on your **Apple Watch** | Log sets from your wrist, phone in the locker |
| 2 | Plate calculator (callout card over the workout) | Know what to **load on the bar** | Plate calculator for every barbell lift |
| 3 | Active workout with the custom keypad open, previous-lift column visible | Log every set **in seconds** | Custom keypad, last lift right beside it |
| 4 | Workout tab with folder expanded | Routines ready **in one tap** | Templates and folders for every split |
| 5 | History | Every workout, **every PR** | Volume, duration and records at a glance |
| 6 | Profile dashboard (reads "Ashton") | Hit your **weekly goal** | Dashboard charts your consistency |
| 7 | Workout summary | Finish strong, **share it** | A summary you can send to your crew |
| 8 | Exercise library | Hundreds of exercises, **plus your own** | Search by body part or create custom moves |

iPad overrides: hero subcaption reads "A custom keypad built for the gym floor" (the keypad covers the
previous-lift column in the iPad form sheet); all iPad captions sit on one line except shot 7.

App Store Connect ▸ Flex ▸ version ▸ *iPhone 6.9" Display* (`out/iphone-6.9/`) and
*iPad 13" Display* (`out/ipad-13/`). Apple scales these to the smaller sizes.

## Apple Watch screenshots (1.1.0)

Captured by `FlexWatchUITests/WatchScreenshotTests` on the Apple Watch Series 11 (46mm) simulator
(`scripts/screenshots.sh --watch-only`), uploaded as captured from `appstore/screenshots/out-watch/`
under *Apple Watch Series 10* (416 × 496): the watch has no frame or caption, and `shotkit` knows no
watch device, which is why they sit beside `out/`, not in it. `scripts/gates/watch-screenshots.sh`
holds the sizes and the count.

| # | Screen |
|---|---|
| 1 | Home: the Heavy Duty folder's templates and this week's 2/3 |
| 2 | Logging: Heavy Push, Set 1 of 2, 185 lb × 8 under the Digital Crown |
| 3 | Rest: the countdown and Skip after a set is done |
| 4 | Finished: duration, volume and "Will save when your iPhone is nearby" |

## Before shipping 1.1.0

- **Version 1.1.0, build 10** (bumped 2026-10-30), every target, watch and widget included.
- **No SwiftData model changed in EPIC_001**, so no CloudKit schema deploy this time.
- **HealthKit**: both apps carry the entitlement and usage strings (`health-usage-strings.sh`);
  App Review may ask to see the Health permission flow, which only a watch workout shows.
  CHORE_002 (privacy page published, App Privacy answers) and CHORE_003 (a real gym session on a
  real watch) are done before the upload.
- Upload: `../launch/bin/launch release flex`.

## Before shipping 1.0.3 (kept for the record)

- **Deployment target is now iOS 18.0** (was 26.2). Test on an iOS 18 device or
  simulator; the UI test suite runs on iOS 18.3 in CI-less local runs.
- **CloudKit schema:** the `Exercise` model gained an `isArchived` attribute
  (replacing the broken `isDeleted`). Run the app once against the CloudKit
  *Development* environment, then in CloudKit Console deploy the schema changes
  to *Production* before releasing, or sync will reject the new field.
- Version 1.0.3, build 9 (bumped 2026-09-05).
