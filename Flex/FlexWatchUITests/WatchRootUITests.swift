import XCTest

final class WatchRootUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testWaitsForThePhoneWithoutASnapshot() {
        let app = XCUIApplication()
        app.launchEnvironment["FLEX_DEMO"] = "empty"
        app.launch()

        XCTAssertTrue(app.staticTexts["watch-waiting"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["watch-waiting"].label, "Open Flex on your iPhone to get started")
    }
}
