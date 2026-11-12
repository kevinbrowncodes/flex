# BUG_003 — App Review finds no way to delete an account

**Status:** Open (2026-11-12). Found by App Review on 1.1.0 build 10, submission
43622ff7-651f-497c-b126-ce423c9e1469, reviewed 2026-11-12 on iPhone 17 Pro Max and iPad Air
11-inch (M3), rejected under guideline 5.1.1(v). Fixed by STORY_015.

## Summary

Flex signs people in with Sign in with Apple and keeps that sign-in in iCloud, which App Review
counts as account creation. Since 2022 an app that creates accounts must let people start
deleting the account inside the app. Settings offers Log Out and nothing else, so 1.1.0 was
rejected. App Review offered to approve 1.1.0 as a bug-fix submission and take the fix in the next
update; the owner chose to fix it now and resubmit (2026-11-12).

## Steps to Reproduce

1. Launch Flex and sign in with Apple on the welcome screen.
2. Open Profile ▸ Settings (the gear).
3. Look for a way to delete the account: there is Log Out only.

## Expected vs Actual

- Expected: Settings offers Delete Account, which after one confirmation erases what Flex holds
  for the person and signs them out.
- Actual: Log Out keeps every workout, template, custom exercise and preference in iCloud; nothing
  in the app deletes them.

## Root Cause

Sign in with Apple was added in February 2026 as a welcome gate, and nothing then checked for the
deletion rule that comes with it. Flex has no server, so "the account" is the sign-in record and
preferences in iCloud key-value storage plus the SwiftData store synced to the person's private
CloudKit database; none of it had a delete path. Launch's preflight now catches the gap
(`review_info.account_deletion`, added 2026-11-11, after this submission).

## Acceptance Criteria

- [x] STORY_015 is Done: Settings ▸ Delete Account erases the data and signs out.
- [ ] `appstore/asc_meta.json` names where deletion lives (`review_info.account_deletion`), and
      the device recording App Review asked for shows sign-in, the way to Delete Account and the
      whole deletion (CHORE_006).
- [ ] 1.1.0 is resubmitted with the fixed build; the submission id is appended here.
