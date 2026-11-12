# CHORE_006 — The App Review recording on a real iPhone

**Status:** Open (2026-11-12). BUG_003 and BUG_004 wait on it.

## Summary

App Review asked for a screen recording from a physical device that shows signing in, the way to
Delete Account, the whole deletion, and where Flex names Apple Health. Launch makes it with
`bin/launch record-review flex`, which runs `FlexUITests/ReviewDemoTests` on a connected iPhone
while recording the screen. Sign in with Apple stops for Face ID, which only the owner can give.

## Why

App Review said to reply with the recording and to put it in the App Review Information for future
submissions; Launch's preflight refuses a release without one. Anything only the owner can do is a
chore (CLAUDE.md).

## Changes

- [ ] With the iPhone 13 Pro (signed in to a test Apple Account, the owner's answer 2026-11-12)
      connected to the Mac Studio 2022 and unlocked, Hands types `bin/launch record-review flex`
      into Terminal on that Mac's screen (signing fails over ssh), and the owner, at the phone,
      approves the Sign in with Apple sheet with Face ID; the test waits up to five minutes.
- [ ] Claude, after: checks the recording and its `.json` sidecar exist, runs
      `bin/launch preflight flex`, and continues the release in BUG_003 and BUG_004.

## Testing

The recording test asserts each screen before it moves on, so a broken flow cannot be filmed.
