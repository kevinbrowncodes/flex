import XCTest

final class WatchWorkoutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(resume: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FLEX_DEMO"] = "sample"
        if resume { app.launchEnvironment["FLEX_DEMO_RESUME"] = "1" }
        app.launch()
        return app
    }

    private func startHeavyPush(_ app: XCUIApplication) {
        let heavyPush = app.staticTexts["Heavy Push"]
        XCTAssertTrue(heavyPush.waitForExistence(timeout: 15))
        heavyPush.tap()
        let start = app.buttons["watch-start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        XCTAssertTrue(app.staticTexts["watch-set-label"].waitForExistence(timeout: 10))
    }

    func testStartLogRestAndFinish() {
        let app = launch()
        startHeavyPush(app)

        XCTAssertEqual(app.staticTexts["watch-set-label"].label, "Set 1 of 2")
        XCTAssertEqual(app.staticTexts["watch-weight"].label, "185")
        XCTAssertEqual(app.staticTexts["watch-reps"].label, "8")

        app.buttons["watch-done"].tap()
        XCTAssertTrue(app.staticTexts["watch-rest"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["watch-set-label"].label, "Set 2 of 2")
        XCTAssertEqual(app.staticTexts["watch-weight"].label, "205")

        app.buttons["watch-rest-skip"].tap()
        XCTAssertFalse(app.staticTexts["watch-rest"].waitForExistence(timeout: 2))

        // The last set of this exercise: Done moves to the next exercise's page.
        app.buttons["watch-done"].tap()
        XCTAssertTrue(app.staticTexts["Incline Bench Press (Barbell)"].waitForExistence(timeout: 5))

        // Page down to Finish.
        let finish = app.buttons["watch-finish"]
        var swipes = 0
        while !finish.exists && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["watch-finish-sets"].label, "2 of 7 sets")
        finish.tap()

        XCTAssertTrue(app.staticTexts["watch-finished"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["watch-finished-status"].label, "Will save when your iPhone is nearby")
        app.buttons["watch-finished-done"].tap()
        XCTAssertTrue(app.staticTexts["Heavy Push"].waitForExistence(timeout: 5))
    }

    func testWorkoutInProgressSurvivesRelaunch() {
        var app = launch()
        startHeavyPush(app)
        app.buttons["watch-done"].tap()
        XCTAssertEqual(app.staticTexts["watch-set-label"].label, "Set 2 of 2")

        app.terminate()
        app = launch(resume: true)

        XCTAssertTrue(app.staticTexts["watch-set-label"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["watch-set-label"].label, "Set 2 of 2")
        XCTAssertTrue(app.staticTexts["Bench Press (Barbell)"].exists)
    }
}
