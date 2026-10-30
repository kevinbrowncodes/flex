import XCTest

final class WorkoutFlowUITests: FlexUITestCase {
    func testTabsLoadWithSampleData() {
        launch(tab: "profile")
        waitFor(app.staticTexts["Alex"])
        waitFor(app.staticTexts["Dashboard"])

        selectTab("History")
        waitFor(app.staticTexts["Chest Day"])

        selectTab("Exercises")
        waitFor(app.staticTexts["Bench Press (Barbell)"].firstMatch)

        selectTab("Workout")
        waitFor(app.buttons["start-empty-workout"])
        waitFor(app.buttons["folder-Heavy Duty"])
        // Templates inside a folder must not also be listed as unorganized templates.
        XCTAssertFalse(app.buttons["template-card-Heavy Push"].exists)
        waitFor(app.buttons["template-card-Full Body Workout"])
    }

    func testTemplateWorkoutPrefillsSetsAndShowsPreviousPerformance() {
        launch()
        startPushDayWorkout()

        XCTAssertTrue(app.staticTexts["Heavy Push"].exists)
        // Sets come from the template…
        let firstWeight = app.buttons["weight-Bench Press (Barbell)-1"]
        waitFor(firstWeight)
        XCTAssertEqual(firstWeight.value as? String, "185")
        // …and the "Previous" column comes from the generated history, not from the current sets.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '× 8'")).firstMatch.exists)
    }

    func testPlateCalculatorOpensForBarbellExercises() {
        launch()
        startPushDayWorkout()

        tap(app.buttons["weight-Bench Press (Barbell)-1"])
        tap(app.buttons["numberpad-plates"])
        waitFor(app.staticTexts["plate-target"])
        XCTAssertEqual(app.staticTexts["plate-target"].label, "185 lb")
        XCTAssertTrue(app.staticTexts["Olympic Barbell (45 lb)"].exists)
    }

    func testNumberPadEditsWeight() {
        launch()
        startPushDayWorkout()

        tap(app.buttons["weight-Bench Press (Barbell)-1"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["numberpad-2"])
        tap(app.buttons["numberpad-0"])
        tap(app.buttons["numberpad-5"])
        tap(app.buttons["numberpad-done"])
        XCTAssertEqual(app.buttons["weight-Bench Press (Barbell)-1"].value as? String, "205")
    }

    func testFinishWorkoutSavesToHistoryAndCountsPR() {
        launch()
        startPushDayWorkout()

        // Log a heavier top set than any previous session (the sample history tops out at 245).
        tap(app.buttons["weight-Bench Press (Barbell)-2"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["numberpad-2"])
        tap(app.buttons["numberpad-5"])
        tap(app.buttons["numberpad-5"])
        tap(app.buttons["numberpad-done"])
        XCTAssertEqual(app.buttons["weight-Bench Press (Barbell)-2"].value as? String, "255")
        tap(app.buttons["complete-Bench Press (Barbell)-1"])
        tap(app.buttons["complete-Bench Press (Barbell)-2"])

        tap(app.buttons["finish-workout"])
        tap(app.buttons["Finish Workout"])

        waitFor(app.staticTexts["Great Job!"])
        // 255 beats every earlier bench press, so at least one PR is awarded.
        let prLabel = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*[1-9][0-9]* PRs?.*'")).firstMatch
        XCTAssertTrue(prLabel.waitForExistence(timeout: 3), "expected a PR count on the summary")
        tap(app.buttons["summary-close"])

        selectTab("History")
        let card = app.otherElements["workout-card-Heavy Push"].firstMatch
        waitFor(card)
        XCTAssertTrue(card.staticTexts["255 lb × 6"].exists)
    }

    func testWorkoutInProgressSurvivesRelaunch() {
        launch()
        startPushDayWorkout()

        tap(app.buttons["weight-Bench Press (Barbell)-1"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete"])
        tap(app.buttons["numberpad-2"])
        tap(app.buttons["numberpad-0"])
        tap(app.buttons["numberpad-5"])
        tap(app.buttons["numberpad-done"])
        tap(app.buttons["complete-Bench Press (Barbell)-1"])
        XCTAssertEqual(app.buttons["weight-Bench Press (Barbell)-1"].value as? String, "205")

        // iOS kills Flex mid-workout…
        app.terminate()
        // …and on the next launch, landing on Profile, the workout is back on top with every set.
        launch(tab: "profile", extra: ["FLEX_DEMO_RESUME": "1"])
        waitFor(app.buttons["finish-workout"], timeout: 15)
        XCTAssertTrue(app.staticTexts["Heavy Push"].exists)
        XCTAssertEqual(app.buttons["weight-Bench Press (Barbell)-1"].value as? String, "205")
        XCTAssertEqual(app.buttons["complete-Bench Press (Barbell)-1"].label, "Completed")

        tap(app.buttons["cancel-workout"])
        tap(app.buttons["Discard Workout"])
        waitFor(app.buttons["start-empty-workout"])
    }

    func testCancelWithLoggedSetsAsksForConfirmation() {
        launch()
        startPushDayWorkout()

        tap(app.buttons["cancel-workout"])
        waitFor(app.buttons["Discard Workout"])
        tap(app.buttons["Keep Going"])
        XCTAssertTrue(app.buttons["finish-workout"].exists)

        tap(app.buttons["cancel-workout"])
        tap(app.buttons["Discard Workout"])
        waitFor(app.buttons["start-empty-workout"])
    }

    func testEmptyWorkoutCanAddExerciseAndFinish() {
        launch(dataset: "empty")
        tap(app.buttons["start-empty-workout"])
        XCTAssertTrue(app.staticTexts["Add an exercise to get started"].waitForExistence(timeout: 5))

        tap(app.buttons["add-exercises"])
        let search = app.textFields["exercise-picker-search"]
        tap(search)
        search.typeText("Pull Up")
        tap(app.buttons["pick-exercise-Pull Up"])
        tap(app.buttons["add-selected-exercises"])

        tap(app.buttons["reps-Pull Up-1"])
        tap(app.buttons["numberpad-1"])
        tap(app.buttons["numberpad-0"])
        tap(app.buttons["numberpad-done"])
        tap(app.buttons["add-set-Pull Up"])
        // The new set copies the previous set's reps.
        XCTAssertEqual(app.buttons["reps-Pull Up-2"].value as? String, "10")

        tap(app.buttons["finish-workout"])
        tap(app.buttons["Finish Workout"])
        waitFor(app.staticTexts["Great Job!"])
        tap(app.buttons["summary-close"])

        selectTab("History")
        waitFor(app.staticTexts["2 × Pull Up"])
    }

    func testEditWorkoutCancelDiscardsAndSaveCommits() {
        launch(tab: "history")
        let card = app.otherElements["workout-card-Chest Day"].firstMatch
        waitFor(card)

        tap(app.buttons["workout-options-Chest Day"])
        tap(app.buttons["Edit Workout"])
        tap(app.buttons["Edit Workout Name"])
        let field = app.textFields["Workout Name"]
        waitFor(field)
        field.tap()
        field.typeText(" Discarded")
        tap(app.alerts.buttons["Save"])
        XCTAssertTrue(app.staticTexts["Chest Day Discarded"].waitForExistence(timeout: 3))
        tap(app.buttons["edit-workout-cancel"])
        XCTAssertFalse(app.staticTexts["Chest Day Discarded"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Chest Day"].exists)

        tap(app.buttons["workout-options-Chest Day"])
        tap(app.buttons["Edit Workout"])
        tap(app.buttons["Edit Workout Name"])
        waitFor(field)
        field.tap()
        field.typeText(" Renamed")
        tap(app.alerts.buttons["Save"])
        tap(app.buttons["edit-workout-save"])
        waitFor(app.staticTexts["Chest Day Renamed"])
    }

    func testCreateCustomExerciseRejectsDuplicateNames() {
        launch(tab: "exercises")
        tap(app.buttons["create-exercise"])
        let nameField = app.textFields["exercise-name"]
        tap(nameField)
        nameField.typeText("Bench Press (Barbell)")
        XCTAssertFalse(app.buttons["save-exercise"].isEnabled)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'already exists'")).firstMatch.waitForExistence(timeout: 3))

        nameField.tap()
        nameField.typeText(" Pause")
        XCTAssertTrue(app.buttons["save-exercise"].isEnabled)
        tap(app.buttons["save-exercise"])
        // The new row can sit below the fold of a lazy list; search brings it into view (CHORE_001).
        let search = app.textFields["exercise-search"]
        tap(search)
        search.typeText("Pause")
        waitFor(app.staticTexts["Bench Press (Barbell) Pause"].firstMatch)
    }

    func testTemplateAndFolderRenameAndDeleteConfirmation() {
        launch()
        tap(app.buttons["Full Body Workout options"])
        tap(app.buttons["Rename"])
        let field = app.textFields["Template name"]
        waitFor(field)
        field.tap()
        field.typeText(" B")
        tap(app.alerts.buttons["Save"])
        waitFor(app.buttons["template-card-Full Body Workout B"])

        tap(app.buttons["Full Body Workout B options"])
        tap(app.buttons["Delete"])
        waitFor(app.buttons["Delete \"Full Body Workout B\""])
        tap(app.buttons["Cancel"])
        XCTAssertTrue(app.buttons["template-card-Full Body Workout B"].exists)

        tap(app.buttons["Full Body Workout B options"])
        tap(app.buttons["Delete"])
        tap(app.buttons["Delete \"Full Body Workout B\""])
        XCTAssertFalse(app.buttons["template-card-Full Body Workout B"].waitForExistence(timeout: 2))
    }

    func testProfileTargetsValidateInput() {
        launch(tab: "profile")
        let targetButtons = app.buttons.matching(identifier: "set-weekly-target")
        tap(targetButtons.firstMatch)
        let field = app.textFields["target-field"]
        waitFor(field)
        field.tap()
        let clear = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3)
        field.typeText(clear + "0")
        XCTAssertFalse(app.buttons["save-target"].isEnabled)
        field.typeText(XCUIKeyboardKey.delete.rawValue + "4")
        XCTAssertTrue(app.buttons["save-target"].isEnabled)
        tap(app.buttons["save-target"])
        waitFor(app.staticTexts["Goal: 4 per week"])
    }
}
