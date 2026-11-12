# STORY_015 — Delete Account erases everything Flex holds

**Status:** Approved by the owner 2026-11-12 through the picker ("Keep sign-in, add Delete", with
the mockup below), after App Review rejected 1.1.0 under 5.1.1(v) (BUG_003).
Done 2026-11-12: built and gated (FlexTests, AccountUITests, the full tests gate on the Mac Studio
2022); the recording waits on CHORE_006.

As Kevin, I want a Delete Account button in Settings that erases my workouts, templates, custom
exercises and preferences from this device and iCloud and signs me out, so that anyone who signed
in can take everything back, as App Review requires.

## UI Mockup

```
Settings                                   Confirmation (alert)
┌──────────────────────────────┐          ┌──────────────────────────────┐
│ …                            │          │      Delete Account?         │
│ ACCOUNT                      │          │ Every workout, template and  │
│   Log Out            (red)   │          │ custom exercise is erased    │
│   Delete Account     (red)   │          │ from this device and iCloud, │
│ Deleting erases your data    │          │ your preferences are reset,  │
│ from this device and iCloud. │          │ and you're signed out. This  │
│                              │          │ can't be undone. Workouts    │
│        Flex 1.1.0 (11)       │          │ already in Apple Health stay │
└──────────────────────────────┘          │ there.                       │
                                          │ [Cancel]   [Delete Account]  │
                                          └──────────────────────────────┘
After Delete: Settings closes and Flex shows the welcome screen.
```

## Acceptance Criteria

- [x] `Flex/Support/AccountEraser.swift` erases every record of every model in the schema (sets,
      exercises in workouts and templates, workouts, templates, folders, exercises) one object at a
      time, so CloudKit mirrors each delete, saves, then re-seeds the bundled exercise library so
      Flex is usable again after a new sign-in.
- [x] `PreferencesManager.reset()` removes the name, weekly and daily targets and rest time from
      iCloud and the device, puts the defaults back, and clears "has seen welcome".
- [x] Settings has an Account section with Log Out and Delete Account. Delete Account asks once
      with the alert above; Delete discards any workout in progress, erases the data, resets the
      preferences, signs out and closes Settings, which leaves the welcome screen showing. A failed
      save shows an alert and signs nobody out.
- [x] Release Flex has no server and cannot revoke the Apple token; the review notes say so and
      say where a person stops using Sign in with Apple for Flex (Settings ▸ Apple Account ▸
      Sign-In & Security ▸ Sign in with Apple).
- [x] `appstore/asc_meta.json`: `review_info.account_deletion` names Profile ▸ Settings ▸ Account
      ▸ Delete Account; `review_info.demo_account` is `not_needed` (any Apple Account signs in).

## Testing Plan

- **Unit, `FlexTests/AccountEraserTests.swift`:** a container with sample data and a custom
  exercise holds no workouts, templates, folders or custom exercises after the erase, and holds
  the bundled library again; erasing an empty store succeeds.
- **Unit, `FlexTests/SupportTests.swift`:** `PreferencesManager.reset()` puts every preference back
  to its default and clears "has seen welcome".
- **UI, `FlexUITests/AccountUITests.swift`:** in `FLEX_DEMO=sample`, Settings ▸ Delete Account ▸
  Cancel keeps the user in Settings; Delete Account ▸ Delete lands on the welcome screen.
- **UI, `FlexUITests/ReviewDemoTests.swift`:** the App Review recording (CHORE_006), skipped unless
  `FLEX_REVIEW_DEMO=1`: real sign-in, the Apple Health section, Delete Account, the welcome screen.
- **Gates:** every gate in `scripts/gates/`, and Launch's preflight for the meta.
- **By hand:** the recording on a physical iPhone, because Sign in with Apple needs Face ID
  (CHORE_006).

## Notes

No model changes, so no CloudKit schema deploy.
