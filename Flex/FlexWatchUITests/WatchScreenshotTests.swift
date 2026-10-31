import XCTest

/// Drives the watch app into each App Store screenshot state and saves a device-pixel PNG
/// (STORY_012). Run via `scripts/screenshots.sh`; the output folder comes from
/// `FLEX_SCREENSHOT_DIR`, and each capture asserts the screen it photographs.
final class WatchScreenshotTests: XCTestCase {
    private var outputDirectory: URL? {
        guard let path = ProcessInfo.processInfo.environment["FLEX_SCREENSHOT_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipIf(outputDirectory == nil, "Set FLEX_SCREENSHOT_DIR to capture screenshots")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FLEX_DEMO"] = "sample"
        // The session looks 41 minutes in, so the clock and the finished screen read like a real workout.
        app.launchEnvironment["FLEX_DEMO_WORKOUT_OFFSET"] = "-2472"
        app.launch()
        return app
    }

    private func capture(_ name: String) throws {
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        let screenshot = XCUIScreen.main.screenshot()
        let directory = try XCTUnwrap(outputDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try screenshot.pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureHomeLoggingRestAndFinished() throws {
        let app = launch()

        let heavyPush = app.staticTexts["Heavy Push"]
        XCTAssertTrue(heavyPush.waitForExistence(timeout: 15))
        try capture("01-home")

        heavyPush.tap()
        let start = app.buttons["watch-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.staticTexts["watch-set-label"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["watch-set-label"].label, "Set 1 of 2")
        try capture("02-logging")

        app.buttons["watch-done"].tap()
        XCTAssertTrue(app.staticTexts["watch-rest"].waitForExistence(timeout: 5))
        try capture("03-rest")

        app.buttons["watch-rest-skip"].tap()
        app.buttons["watch-done"].tap()
        let finish = app.buttons["watch-finish"]
        var swipes = 0
        while !finish.exists && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()
        XCTAssertTrue(app.staticTexts["watch-finished"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["watch-finished-status"].label, "Will save when your iPhone is nearby")
        try capture("04-finished")
    }
}
