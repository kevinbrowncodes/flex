# BUG_002 — App Review rejects Apple Watch in the subtitle

**Status:** Resolved (2026-11-10). Found by App Review on 1.1.0 build 10, submission
43622ff7-651f-497c-b126-ce423c9e1469, rejected 19:27 under guideline 5.2.5.

## Summary

STORY_012 gave 1.1.0 the subtitle "Workout log & Apple Watch". App Review rejected the version:
the metadata uses "terms for Apple Watch in the app subtitle in an inappropriate manner". The
subtitle sits beside the app name on the store, so an Apple product name there reads as part of
the product's name, which Apple's trademark guidelines forbid. The build itself was not faulted.

## Steps to Reproduce

1. Read `appstore/asc_meta.json`: `"subtitle": "Workout log & Apple Watch"`.
2. `launch release flex` sets it on the version's app info and submits.
3. App Review answers with guideline 5.2.5 (Legal, Intellectual Property, Apple Products).

## Expected vs Actual

- Expected: the listing names the watch feature without an Apple product name in the name or
  subtitle, and 1.1.0 passes review.
- Actual: 1.1.0 is Rejected; the review message names the subtitle alone.

## Root Cause

Nothing checked the name and subtitle for Apple trademarks. Apple allows its word marks only in a
referential phrase ("works with Apple Watch") and never as part of a product name; the subtitle
used the mark as a feature in a list. The promotional text, What's New, the first screenshot
caption and the preview overlay mention Apple Watch as compatibility references and were not
cited; the owner chose to change the subtitle alone (picker, 2026-11-10).

## Acceptance Criteria

- [x] `appstore/asc_meta.json`'s subtitle is "Workout log, on your wrist" (26 of 30 characters),
      the owner's choice through the picker.
- [x] `scripts/gates/store-names.sh` fails when the app name or subtitle in
      `appstore/asc_meta.json` names an Apple product or service (Apple, Apple Watch, iPhone,
      iPad, Mac, iOS, watchOS, Siri, HealthKit, Apple Health, iCloud, AirPods), with the rule and
      the fix in its message; it proves itself on planted metadata first. `CLAUDE.md` and
      `README.md` list it.
- [x] Launch sets the new subtitle on 1.1.0 (`launch asc flex set-subtitle`) and resubmits build
      10 (`launch asc flex submit`); the submission id is appended here.

## Testing

- **Unit (shell):** `store-names.sh` refuses a planted subtitle "Workout log & Apple Watch" and a
  planted name with "iPhone", passes a planted "Workout log, on your wrist", then checks the real
  file.
- **Gates:** every gate in `scripts/gates/`. No app code changes, so no new unit or UI tests.
- **By hand:** none; App Review's answer is the end-to-end check.

## Resolution

2026-11-10: the subtitle is "Workout log, on your wrist", set on 1.1.0's editable app info by
`launch asc flex set-subtitle` (the live 1.0.3 listing keeps its own). Launch's `submit` could
not resubmit a rejected version: Apple keeps it in its submission (UNRESOLVED_ISSUES, item
REJECTED) and refuses it in any other. `submit` now marks the rejected item resolved and submits
that same submission again, which is what "Resubmit to App Review" does. 1.1.0 build 10 went back
to WAITING_FOR_REVIEW under submission 43622ff7-651f-497c-b126-ce423c9e1469.
