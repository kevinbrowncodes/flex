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

`appstore/asc_meta.json` drives `../ascpilot/bin/release.sh` (archive, upload, create
version, metadata, screenshots, attach build, submit). Version 1.0.3 / build 9 was
uploaded this way on 2026-09-05.

## Description — suggested closing paragraph

> Flex is designed and built by two fitness freaks, Ashton Krstolic and Kevin Brown.
> Every feature exists because we needed it at the rack. Questions or ideas?
> Open an issue on our support page — we read every one.

## Screenshots

Upload from `appstore/screenshots/out/` in numeric order. Shots 1–2 are the ones
that appear in App Store search results.

| # | Screen | Caption | Subcaption |
|---|---|---|---|
| 1 | Active workout with the custom keypad open, previous-lift column visible | Log every set **in seconds** | Custom keypad, last lift right beside it |
| 2 | Plate calculator (callout card over the workout) | Know what to **load on the bar** | Plate calculator for every barbell lift |
| 3 | Workout tab with folder expanded | Routines ready **in one tap** | Templates and folders for every split |
| 4 | History | Every workout, **every PR** | Volume, duration and records at a glance |
| 5 | Profile dashboard | Hit your **weekly goal** | Dashboard charts your consistency |
| 6 | Workout summary | Finish strong, **share it** | A summary you can send to your crew |
| 7 | Exercise library | Hundreds of exercises, **plus your own** | Search by body part or create custom moves |

iPad overrides: hero subcaption reads "A custom keypad built for the gym floor" (the keypad covers the
previous-lift column in the iPad form sheet); all iPad captions sit on one line except shot 7.

App Store Connect ▸ Flex ▸ version ▸ *iPhone 6.9" Display* (`out/iphone-6.9/`) and
*iPad 13" Display* (`out/ipad-13/`). Apple scales these to the smaller sizes.

## Before shipping this build

- **Deployment target is now iOS 18.0** (was 26.2). Test on an iOS 18 device or
  simulator; the UI test suite runs on iOS 18.3 in CI-less local runs.
- **CloudKit schema:** the `Exercise` model gained an `isArchived` attribute
  (replacing the broken `isDeleted`). Run the app once against the CloudKit
  *Development* environment, then in CloudKit Console deploy the schema changes
  to *Production* before releasing, or sync will reject the new field.
- Version 1.0.3, build 9 (bumped 2026-09-05).
