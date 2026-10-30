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

- Open `Flex/Flex.xcodeproj`, scheme **Flex**. The project uses Xcode folder-synchronized
  groups: any file dropped into `Flex/Flex`, `Flex/FlexTests` or `Flex/FlexUITests` is
  compiled automatically.
- Deployment target: iOS 18.0.
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
```

## Scripts

| Script | Purpose |
|---|---|
| `scripts/screenshots.sh` | Capture, compose and verify App Store screenshots (see `appstore/screenshots/README.md`) |
| `scripts/generate-app-icon.sh` | Re-render every AppIcon PNG from `Support/FlexAppIcon.swift` |

## Links

- Support site: https://kevinbrowncodes.github.io/flex-support/ (repo `kevinbrowncodes/flex-support`)
- Privacy policy: https://kevinbrowncodes.github.io/flex-support/privacy
