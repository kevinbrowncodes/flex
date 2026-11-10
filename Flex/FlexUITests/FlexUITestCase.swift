import XCTest

/// Base class: launches the app in demo mode (in-memory data, signed in) and offers navigation helpers.
class FlexUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// - Parameters:
    ///   - dataset: `"sample"` for rich demo data, `"empty"` for just the exercise library.
    ///   - tab: initial tab (`profile`, `history`, `exercises`, `workout`).
    @discardableResult
    func launch(dataset: String = "sample", tab: String = "workout", theme: String = "Light", extra: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FLEX_DEMO"] = dataset
        app.launchEnvironment["FLEX_TAB"] = tab
        app.launchEnvironment["FLEX_THEME"] = theme
        app.launchEnvironment["FLEX_USER_NAME"] = "Ashton"
        for (key, value) in extra {
            app.launchEnvironment[key] = value
        }
        app.launch()
        self.app = app
        return app
    }

    func selectTab(_ name: String) {
        let tabButton = app.tabBars.buttons[name]
        if tabButton.waitForExistence(timeout: 3) {
            tabButton.tap()
        } else {
            // iPadOS 18+ places the tab bar at the top of the screen.
            let button = app.buttons[name].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing tab \(name)")
            button.tap()
        }
    }

    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Timed out waiting for \(element)", file: file, line: line)
    }

    func tap(_ element: XCUIElement, timeout: TimeInterval = 8, file: StaticString = #filePath, line: UInt = #line) {
        waitFor(element, timeout: timeout, file: file, line: line)
        element.tap()
    }

    /// Scrolls the first scroll view until the element is hittable (or gives up).
    func scrollTo(_ element: XCUIElement, in container: XCUIElement? = nil, maxSwipes: Int = 6) {
        let scrollable = container ?? app.scrollViews.firstMatch
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            scrollable.swipeUp(velocity: .slow)
            swipes += 1
        }
    }

    /// Starts the "Heavy Push" template workout from the Workout tab.
    func startPushDayWorkout() {
        selectTab("Workout")
        tap(app.buttons["folder-Heavy Duty"])
        let card = app.buttons["template-card-Heavy Push"]
        scrollTo(card)
        tap(card)
        tap(app.buttons["start-template-workout"])
        waitFor(app.buttons["finish-workout"], timeout: 15)
    }
}
