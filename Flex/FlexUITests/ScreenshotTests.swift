import XCTest

/// Drives the app into each App Store screenshot state and saves a device-pixel PNG.
/// Run via `scripts/screenshots.sh`; the output directory comes from `FLEX_SCREENSHOT_DIR`.
final class ScreenshotTests: FlexUITestCase {
    private var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["FLEX_SCREENSHOT_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private var theme: String {
        ProcessInfo.processInfo.environment["FLEX_SCREENSHOT_THEME"] ?? "Dark"
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipIf(outputDirectory == nil, "Set FLEX_SCREENSHOT_DIR to capture screenshots")
    }

    private func capture(_ name: String) throws {
        // Let animations settle before capturing.
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        let screenshot = XCUIScreen.main.screenshot()
        let directory = try XCTUnwrap(outputDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(name).png")
        try screenshot.pngRepresentation.write(to: url)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureActiveWorkoutAndPlateCalculator() throws {
        // Make the session look 41 minutes in so the timer and summary read like a real workout.
        launch(theme: theme, extra: ["FLEX_DEMO_WORKOUT_OFFSET": "-2472"])
        startPushDayWorkout()
        tap(app.buttons["complete-Bench Press (Barbell)-1"])
        // Hero: the custom keypad open on the second set, previous lift beside it.
        tap(app.buttons["weight-Bench Press (Barbell)-2"])
        waitFor(app.buttons["numberpad-done"])
        try capture("02-active-workout")

        tap(app.buttons["numberpad-plates"])
        waitFor(app.staticTexts["plate-target"])
        try capture("03-plate-calculator")

        // Load a 45 on each side (205 → 295) so the summary shows a personal record.
        tap(app.buttons["Add 45 pound plate"])
        tap(app.buttons["Back to keypad"])
        tap(app.buttons["numberpad-done"])
        tap(app.buttons["complete-Bench Press (Barbell)-2"])
        tap(app.buttons["finish-workout"])
        tap(app.buttons["Finish Workout"])
        waitFor(app.staticTexts["Great Job!"])
        try capture("06-summary")
    }

    func testCaptureWatchHero() throws {
        // Shot 1 (STORY_013): the workout 41 minutes in, the first bench set done, rest counting,
        // and the watch linked at 128 bpm, so the header reads "♥ 128 · On watch".
        launch(theme: theme, extra: ["FLEX_DEMO_WORKOUT_OFFSET": "-2472", "FLEX_DEMO_WATCH": "128"])
        startPushDayWorkout()
        waitFor(app.descendants(matching: .any)["live-on-watch"])
        waitFor(app.descendants(matching: .any)["live-heart-rate"])
        tap(app.buttons["complete-Bench Press (Barbell)-1"])
        waitFor(app.staticTexts["rest-timer"])
        try capture("00-watch-hero")
    }

    func testCaptureTemplates() throws {
        launch(theme: theme)
        selectTab("Workout")
        tap(app.buttons["folder-Heavy Duty"])
        try capture("01-templates")
    }

    func testCaptureHistoryAndCalendar() throws {
        launch(tab: "history", theme: theme)
        waitFor(app.staticTexts["Chest Day"])
        try capture("04-history")

        tap(app.buttons["history-calendar"])
        waitFor(app.staticTexts["Workout Calendar"])
        try capture("07-calendar")
    }

    func testCaptureProfile() throws {
        launch(tab: "profile", theme: theme)
        waitFor(app.staticTexts["Dashboard"])
        waitFor(app.staticTexts["Ashton"]) // the demo lifter's name on the store shot (STORY_013)
        try capture("05-profile")
    }

    func testCaptureExercises() throws {
        launch(tab: "exercises", theme: theme)
        waitFor(app.staticTexts["Bench Press (Barbell)"].firstMatch)
        try capture("08-exercises")
    }
}
