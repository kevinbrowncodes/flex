import XCTest

/// Settings names Apple Health (STORY_016, BUG_004) and deletes the account (STORY_015, BUG_003).
final class AccountUITests: FlexUITestCase {
    private func openSettings() {
        launch(tab: "profile")
        tap(app.buttons["open-settings"])
        waitFor(app.navigationBars["Settings"])
    }

    func testSettingsNamesAppleHealth() {
        openSettings()
        let health = app.descendants(matching: .any)["apple-health-info"]
        scrollTo(health, in: app.collectionViews.firstMatch)
        waitFor(health)
        XCTAssertTrue(health.label.contains("Flex works with Apple Health"), health.label)
        XCTAssertTrue(health.label.contains("heart rate"), health.label)
    }

    func testDeleteAccountCancelKeepsEverything() {
        openSettings()
        let delete = app.buttons["delete-account"]
        scrollTo(delete, in: app.collectionViews.firstMatch)
        tap(delete)
        let alert = app.alerts["Delete Account?"]
        waitFor(alert)
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "can't be undone")).firstMatch.exists)
        tap(alert.buttons["Cancel"])
        waitFor(app.navigationBars["Settings"])
        XCTAssertTrue(app.buttons["delete-account"].exists)
    }

    func testDeleteAccountErasesAndReturnsToWelcome() {
        openSettings()
        let delete = app.buttons["delete-account"]
        scrollTo(delete, in: app.collectionViews.firstMatch)
        tap(delete)
        tap(app.alerts["Delete Account?"].buttons["Delete Account"])
        waitFor(app.staticTexts["Welcome to Flex"])
        waitFor(app.descendants(matching: .any)["sign-in-with-apple"].firstMatch)
    }
}
