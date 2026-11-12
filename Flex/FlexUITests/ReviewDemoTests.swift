import XCTest

/// The screen recording App Review asked for on 2026-11-12 (5.1.1(v) and 2.5.1, BUG_003, BUG_004):
/// on a physical iPhone, from the Home Screen, launch Flex signed out, sign in with Apple, show
/// where Flex names Apple Health, then delete the account from start to confirmation.
///
/// Launch records it with `bin/launch record-review flex` (CHORE_006). Sign in with Apple stops
/// for Face ID, which the owner gives at the phone; the test waits up to five minutes for it.
/// Skipped unless FLEX_REVIEW_DEMO is set, so `scripts/gates/tests.sh` never runs it:
///   TEST_RUNNER_FLEX_REVIEW_DEMO=1 xcodebuild test -project Flex/Flex.xcodeproj -scheme Flex \
///     -destination 'platform=iOS,name=<iPhone>' -only-testing:FlexUITests/ReviewDemoTests/testReviewDemo
final class ReviewDemoTests: FlexUITestCase {
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["FLEX_REVIEW_DEMO"] != nil,
                          "The review demo runs only with TEST_RUNNER_FLEX_REVIEW_DEMO=1 (see ReviewDemoTests.swift)")
        try super.setUpWithError()
    }

    func testReviewDemo() {
        // 1 · The Home Screen, before Flex opens.
        XCUIDevice.shared.press(.home)
        hold(3)

        // 2 · Launch Flex signed out: the welcome screen and Sign in with Apple.
        app = XCUIApplication()
        app.launchEnvironment["FLEX_SIGNED_OUT"] = "1"
        app.launch()
        waitFor(app.staticTexts["Welcome to Flex"], timeout: 15)
        hold(3)

        // 3 · Sign in with Apple. Apple's sheet asks for Face ID, which the owner gives.
        tap(app.descendants(matching: .any)["sign-in-with-apple"].firstMatch)
        let proceed = springboard.buttons["Continue"]
        if proceed.waitForExistence(timeout: 10) {
            hold(2)
            proceed.tap()
        }
        waitFor(app.buttons["open-settings"].firstMatch, timeout: 300, orTab: "Profile")
        hold(3)

        // 4 · Settings names Apple Health and says what Flex saves and reads.
        tap(app.buttons["open-settings"])
        waitFor(app.navigationBars["Settings"])
        hold(2)
        let health = app.descendants(matching: .any)["apple-health-info"]
        scrollTo(health, in: app.collectionViews.firstMatch, maxSwipes: 3)
        waitFor(health)
        XCTAssertTrue(health.label.contains("Flex works with Apple Health"), health.label)
        hold(6)

        // 5 · Delete Account, its warning, and the deletion through to the welcome screen.
        let delete = app.buttons["delete-account"]
        scrollTo(delete, in: app.collectionViews.firstMatch)
        hold(2)
        tap(delete)
        let alert = app.alerts["Delete Account?"]
        waitFor(alert)
        hold(6)
        tap(alert.buttons["Delete Account"])
        waitFor(app.staticTexts["Welcome to Flex"], timeout: 15)
        waitFor(app.descendants(matching: .any)["sign-in-with-apple"].firstMatch)
        hold(4)
    }

    /// Waits for the signed-in app, opening `tab` once its tab bar shows.
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval, orTab tab: String) {
        let tabBar = app.tabBars.firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline && !tabBar.exists && !app.buttons[tab].exists {
            usleep(500_000)
        }
        selectTab(tab)
        waitFor(element)
    }

    /// Pauses so a viewer of the recording can read the step.
    private func hold(_ seconds: Double) {
        usleep(useconds_t(seconds * 1_000_000))
    }
}
