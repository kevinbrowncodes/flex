# CHORE_002 — App Store Connect declares Health data and the privacy page is published

**Status:** Open (2026-10-30). Waits on STORY_008; STORY_012 waits on it.

## Summary

Flex 1.1.0 reads heart rate and active energy and writes workouts to Apple Health (STORY_008).
Two things only the owner can do follow from that: the privacy policy the App Store links to must
say so on the live site, and App Store Connect's App Privacy answers must match what Flex does
with Health data. STORY_008 writes the Health section into the `kevinbrowncodes/flex-support`
repository; this chore is the publishing and the answers.

## Why

App Review checks that an app with the HealthKit entitlement has a privacy policy covering
Health data and that the App Privacy answers are consistent with it; a mismatch is a rejection
that costs a review cycle. Anything only the owner can do is a chore the moment work stops on it
(CLAUDE.md).

## Changes

- [ ] The owner pushes `kevinbrowncodes/flex-support` (or approves Claude pushing it) so
      https://kevinbrowncodes.github.io/flex-support/privacy shows the Health section, and
      opens the page once to confirm.
- [ ] The owner opens App Store Connect ▸ Flex ▸ App Privacy and sets the answers for Health &
      Fitness: Flex reads heart rate and active energy and writes workouts; the data stays on the
      device and in the user's Health store, is not linked to identity by Flex, and is not used for
      tracking. If Apple's definition of "collected" (data sent off the device) leaves the app at
      "Data Not Collected", the owner keeps that answer and notes it here.
- [ ] Claude, after: records the answer given and the date in this chore's Status line and in
      STORY_012.

2026-10-31: the owner approved the push through the picker and Claude pushed `flex-support`
(commit dc70afc); GitHub Pages publishes it within minutes. Opening the page to confirm the
"Health" heading, and the App Privacy answers, remain the owner's steps above.

## Testing

- **Unit / integration / e2e:** N/A, a store configuration and a published page.
- **By hand:** the privacy URL in App Store Connect opens to a page with a "Health" heading.
