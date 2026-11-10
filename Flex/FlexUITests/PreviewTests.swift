import XCTest

/// Plays the App Store preview storyboard (STORY_014) while `scripts/preview.sh` records the
/// simulator's screen. Each beat writes a wall-clock mark into `FLEX_PREVIEW_DIR`, which the script
/// turns into the overlay windows. Skipped unless `FLEX_PREVIEW=1`, so the tests gate never runs it.
/// The clip ends on the summary: a History beat after it ran the clip past Apple's 30 seconds on a
/// busy Mac (corrected while building STORY_014).
final class PreviewTests: FlexUITestCase {
    private let environment = ProcessInfo.processInfo.environment

    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipIf(environment["FLEX_PREVIEW"] != "1", "Set FLEX_PREVIEW=1 to play the preview storyboard")
    }

    /// Lets the screen rest so the recording shows the state, not the transition.
    private func hold(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// `<name>.txt` in `FLEX_PREVIEW_DIR` holds the Unix time this beat began.
    private func mark(_ name: String) throws {
        let directory = try XCTUnwrap(environment["FLEX_PREVIEW_DIR"], "FLEX_PREVIEW_DIR is where the beats go")
        let url = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent("\(name).txt")
        try String(format: "%.3f", Date().timeIntervalSince1970).write(to: url, atomically: true, encoding: .utf8)
    }

    func testPreviewStoryboard() throws {
        launch(theme: "Dark", extra: ["FLEX_DEMO_WORKOUT_OFFSET": "-2472", "FLEX_DEMO_WATCH": "128"])
        selectTab("Workout")
        waitFor(app.buttons["folder-Heavy Duty"])
        try mark("start")

        // The clip begins a second before this beat (scripts/preview.sh): the workout opening
        // with ♥ 128 · On watch in the header, under overlay 1, "Flex, now on Apple Watch".
        startPushDayWorkout()
        waitFor(app.descendants(matching: .any)["live-on-watch"])
        waitFor(app.descendants(matching: .any)["live-heart-rate"])
        try mark("opened")
        hold(2.0) // overlay 2 from two seconds in: Log sets from your wrist

        tap(app.buttons["complete-Bench Press (Barbell)-1"]) // set 1 ticks and rest starts
        waitFor(app.staticTexts["rest-timer"])
        try mark("tick1")
        hold(2.0)
        try mark("restcue") // overlay 3: Rest on a wrist-tap timer
        hold(1.5)
        tap(app.buttons["rest-plus"]) // +15 s, so the countdown visibly moves
        hold(2.0)

        tap(app.buttons["complete-Bench Press (Barbell)-2"]) // set 2 ticks
        try mark("tick2") // overlay 4: Finish with your phone in the locker
        hold(0.5)
        tap(app.buttons["finish-workout"])
        tap(app.buttons["Finish Workout"])
        waitFor(app.staticTexts["Great Job!"])
        try mark("finished") // overlay 5 a moment later: Or just say "Log bench press in Flex"
        hold(4.5)
        try mark("end")
    }
}
