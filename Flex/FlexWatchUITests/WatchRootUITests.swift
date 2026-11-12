import XCTest

final class WatchRootUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(dataset: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FLEX_DEMO"] = dataset
        app.launch()
        return app
    }

    func testWaitsForThePhoneWithoutASnapshot() {
        let app = launch(dataset: "empty")

        XCTAssertTrue(app.staticTexts["watch-waiting"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["watch-waiting"].label, "Open Flex on your iPhone to get started")
    }

    func testShowsTemplatesAndLastWeightsFromTheSample() {
        let app = launch(dataset: "sample")

        let heavyPush = app.staticTexts["Heavy Push"]
        XCTAssertTrue(heavyPush.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["5 exercises"].exists)
        // watchOS 27 no longer exposes a toolbar Text as a static text, so match any element
        // (CHORE_007).
        let week = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@ OR label == %@", "watch-week", "2 of 3 workouts this week")
        ).firstMatch
        XCTAssertTrue(week.waitForExistence(timeout: 5), "the week count is on the home screen")
        XCTAssertEqual(week.label, "2 of 3 workouts this week")

        heavyPush.tap()
        XCTAssertTrue(app.staticTexts["Bench Press (Barbell)"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["watch-last-Bench Press (Barbell)"].label, "last 205 × 6")
    }
}
