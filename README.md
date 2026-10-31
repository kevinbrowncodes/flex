# flex

A modern workout tracking app built with SwiftUI and SwiftData.

## Development Guidelines

### UI Framework
**Always use SwiftUI for all UI components.**

- ✅ Use SwiftUI views, modifiers, and components
- ✅ Use SwiftUI native controls (DatePicker, List, etc.)
- ❌ Do not use UIKit view controllers directly
- ❌ Do not use Storyboards or XIBs
- ❌ Avoid UIViewRepresentable unless absolutely necessary

### Data Persistence
**Always use SwiftData for data management.**

- ✅ Use SwiftData for all data persistence
- ✅ Use @Model for data models
- ✅ Use @Query for fetching data in views
- ❌ Do not use CoreData
- ❌ Do not use third-party database frameworks

### Code Style
- Use clear, descriptive variable and function names
- Keep views focused and single-purpose
- Extract reusable components into separate views
- Use SwiftData for data persistence

### Project Structure
- Keep models in `/Models`
- Keep views in `/Views` with appropriate subfolders
- Keep shared preview data in `/Support/PreviewData.swift`
- Group related functionality together

### Best Practices
- Always provide preview data for views
- Use environment objects and model context appropriately
- Follow Apple's Human Interface Guidelines
- Keep code clean and maintainable

## Building & testing

- Open `Flex/Flex.xcodeproj`, scheme **Flex** (iPhone and iPad) or **FlexWatch** (Apple Watch).
  The project uses Xcode folder-synchronized groups: any file dropped into `Flex/Flex`,
  `Flex/FlexShared` (compiled into both apps), `Flex/FlexWatch`, or one of the four test folders
  (`FlexTests`, `FlexUITests`, `FlexWatchTests`, `FlexWatchUITests`) is compiled automatically.
- Deployment targets: iOS 18.0, watchOS 11.0. The watch app is embedded in the iOS app and runs
  on its own (`kevinbrowncodes.Flex.watchkitapp`).
- **Unit tests** (`FlexTests`, Swift Testing): models, PR/volume math, plate math,
  formatting, the exercise-library sync/merge logic.
- **UI tests** (`FlexUITests`, XCUITest): end-to-end workout flows and the App Store
  screenshot captures. They launch the app with `FLEX_DEMO=sample|empty` (see
  `Support/DemoMode.swift`), which uses an in-memory store and skips sign-in.

```bash
xcodebuild test -project Flex/Flex.xcodeproj -scheme Flex \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FlexTests
xcodebuild test -project Flex/Flex.xcodeproj -scheme Flex \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:FlexUITests/WorkoutFlowUITests
xcodebuild test -project Flex/Flex.xcodeproj -scheme FlexWatch \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)'
```

## Hooks and gates

Once per clone:

```bash
git config core.hooksPath .githooks
```

`.githooks/commit-msg` refuses a commit whose subject does not start with a ticket id from
`docs/` (`STORY_003: …`). `.githooks/pre-push` refuses a push to `main`, a deleted bug or a
rewritten finished ticket, then runs every `scripts/gates/*.sh`; any red gate blocks the push.
Run one by hand with `sh scripts/gates/<name>.sh`. How we work (tickets, gates, workflow) is in
`CLAUDE.md`.

| Gate | What it checks |
|---|---|
| `tickets-shape.sh` | Every ticket under `docs/` has its kind's file name, heading and sections; owner-only steps cite a chore |
| `commit-subjects.sh` | The commit-msg hook judges sample subjects as CLAUDE.md says |
| `tests.sh` | `FlexTests` and `FlexUITests/WorkoutFlowUITests` pass on the iPhone 17 Pro simulator; `FlexWatchTests` and `FlexWatchUITests` pass on the Apple Watch Series 11 (46mm) simulator |
| `shared-is-portable.sh` | Every file under `Flex/FlexShared` imports only Foundation, Observation or AppIntents, so it compiles into the phone and the watch alike |
| `watch-no-swiftdata.sh` | Nothing under `Flex/FlexWatch` imports SwiftData or CloudKit or names a ModelContainer or ModelContext: the phone is the only writer |
| `health-usage-strings.sh` | Every configuration signed with entitlements that grant HealthKit sets both `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` |

## Releasing

Flex ships with [ascpilot](https://github.com/kevinbrowncodes/ascpilot), driven by
`appstore/asc_meta.json` (App Store Connect app 6758920531, bundle `kevinbrowncodes.Flex`, team
793YF22DGM). Live: 1.0.3, build 9 (2026-09-05).

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `Flex/Flex.xcodeproj/project.pbxproj`
   (every upload needs a new build number).
2. Set `version` and `whats_new` in `appstore/asc_meta.json`.
3. If a SwiftData model changed, deploy the CloudKit schema to Production in CloudKit Console first.
4. `ASC_META=appstore/asc_meta.json ../ascpilot/bin/release.sh`

## Scripts

| Script | Purpose |
|---|---|
| `scripts/screenshots.sh` | Capture, compose and verify App Store screenshots (see `appstore/screenshots/README.md`) |
| `scripts/generate-app-icon.sh` | Re-render every AppIcon PNG from `Support/FlexAppIcon.swift` |
| `scripts/gates/*.sh` | The pre-push gates (see Hooks and gates) |

## Links

- Support site: https://kevinbrowncodes.github.io/flex-support/ (repo `kevinbrowncodes/flex-support`)
- Privacy policy: https://kevinbrowncodes.github.io/flex-support/privacy
