# CHORE_003 — A real gym session on a real watch

**Status:** Open (2026-10-30). Waits on STORY_011; STORY_012 waits on it.

## Summary

Simulators cannot pair a watch to a phone for WatchConnectivity, cannot mirror a HealthKit
workout session, cannot take a heart rate, and cannot hear Siri. Everything in EPIC_001 that
depends on two real devices is proven once, by the owner, in a real session, through TestFlight.

## Why

The epic's own definition of done (EPIC_001, Goal) is the owner logging a real gym session on a
real watch. A gate cannot hold this; a chore holds it instead (CLAUDE.md).

## Changes

- [ ] Claude, before: uploads a TestFlight build with STORY_011 landed and writes the build number
      here.
- [ ] The owner installs it on the phone and the watch and, with the phone in the locker, starts
      a template on the watch, logs a workout with the Crown, rests on the wrist timer, finishes,
      and later finds it in History on the phone (STORY_005, STORY_006, STORY_007).
- [ ] The owner, with the phone along, starts a workout on the phone, sees it on the watch, ticks a
      set on each device and sees it on the other, walks out of range and back, and finishes on
      the phone (STORY_009).
- [ ] The owner checks the heart rate on the watch during the workout and the workout in the Health
      app afterwards (STORY_008), and that Flex stayed on screen when the wrist dropped.
- [ ] The owner says "Log bench press in Flex" to the watch mid-workout and sees the set logged
      (STORY_010), and adds the complication to a face and sees the week count move (STORY_011).
- [ ] The owner writes what felt wrong here, as a list; Claude, after: files each item as a bug or a
      backlog item and notes the ticket ids in this chore's Status line.

## Testing

- **Unit / integration / e2e:** N/A, the by-hand check the automated layers cannot do.
- **By hand:** the steps above are the test; each is ticked only after it was done.
