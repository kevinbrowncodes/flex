# BUG_004 — App Review finds no mention of Apple Health on iPhone

**Status:** Open (2026-11-12). Found by App Review on 1.1.0 build 10, submission
43622ff7-651f-497c-b126-ce423c9e1469, reviewed 2026-11-12 on iPhone 17 Pro Max and iPad Air
11-inch (M3), rejected under guideline 2.5.1. Fixed by STORY_016.

## Summary

Guideline 2.5.1 asks an app that uses HealthKit to say so in its interface. The iPhone and iPad
app carries the HealthKit entitlement (it takes the watch's mirrored workout session, STORY_009)
but no screen names Apple Health: the only Health data it shows is a bare "♥ 128" in the active
workout's header, and only while a watch is linked. App Review reviewed on iPhone and iPad, where
it found nothing.

## Steps to Reproduce

1. Launch Flex on an iPhone or iPad with no watch linked.
2. Open every tab and Profile ▸ Settings.
3. Look for "Apple Health" or a word about what Flex reads and writes: there is none.

## Expected vs Actual

- Expected: Settings says Flex works with Apple Health, what it writes and reads, and when; the
  live heart rate says where it comes from.
- Actual: the phone never names Apple Health. The watch asks for Health permission, but App Review
  tested on iPhone and iPad.

## Root Cause

STORY_008 put HealthKit on the watch and STORY_009 gave the phone the entitlement to mirror the
watch's session. Both stories described Health on the watch only; the phone gained the
entitlement without a screen that explains it.

## Acceptance Criteria

- [x] STORY_016 is Done: Settings has an Apple Health section and the live heart rate reads
      "♥ 128 · Apple Health".
- [ ] The device recording App Review asked for shows the Apple Health section (CHORE_006).
- [ ] 1.1.0 is resubmitted with the fixed build; the submission id is appended here.
