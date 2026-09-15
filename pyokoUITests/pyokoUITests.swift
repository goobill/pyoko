import XCTest

/// Exercises the normal production app on a disposable account. Run this target serially.
final class pyokoUITests: XCTestCase {
    @MainActor private func launch() throws -> XCUIApplication {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["PYOKO_ALLOW_UI_TESTS"] == "1",
                          "Set PYOKO_ALLOW_UI_TESTS=1 in the test runner on a disposable device/iCloud account.")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor private func element(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let target = element(id, app)
        XCTAssertTrue(target.waitForExistence(timeout: 10), "Missing \(id)")
        target.tap()
    }

    @MainActor private func scrollTo(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        let target = element(id, app)
        if target.exists && target.isHittable { return target }
        let configuredScroll = app.scrollViews["config.scroll"]
        let scroll = configuredScroll.exists ? configuredScroll : app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        // Scan from the top so prior interactions cannot strand a control above the viewport.
        for upward in [true, false] {
            for _ in 0..<12 {
                if target.exists && target.isHittable { return target }
                #if os(macOS)
                scroll.scroll(byDeltaX: 0, deltaY: upward ? 450 : -450)
                #else
                if upward { scroll.swipeDown() } else { scroll.swipeUp() }
                #endif
            }
        }
        XCTFail("Cannot reach \(id)")
        return target
    }

    @MainActor private func setToggle(_ id: String, _ enabled: Bool, _ app: XCUIApplication) {
        let control = scrollTo(id, app)
        let expected = enabled ? "1" : "0"
        if control.value as? String != expected { control.tap() }
        XCTAssertEqual(control.value as? String, expected, "Toggle \(id)")
    }

    @MainActor private func choose(_ id: String, _ title: String, _ app: XCUIApplication) {
        scrollTo(id, app).tap()
        #if os(macOS)
        let option = app.menuItems[title].firstMatch
        #else
        let option = app.buttons[title].firstMatch
        #endif
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing menu option \(title)")
        option.tap()
    }

    @MainActor private func restart(_ app: XCUIApplication) {
        #if os(macOS)
        if element("settings.form", app).exists { app.typeKey("w", modifierFlags: .command) }
        #endif
        app.terminate(); app.launch()
    }

    @MainActor private func ensureDeck(_ app: XCUIApplication) {
        tap("home.decks", app)
        let install = element("install.jlpt-n5", app)
        let enabled = element("deck.enabled.jlpt-n5", app)
        if install.waitForExistence(timeout: 2) { install.tap() }
        XCTAssertTrue(enabled.waitForExistence(timeout: 30))
        if enabled.value as? String != "Selected" { enabled.tap() }
        XCTAssertEqual(enabled.value as? String, "Selected")
        restart(app)
    }

    @MainActor private func configureCards(_ app: XCUIApplication, quick: Bool, writing: Bool = false) {
        tap(quick ? "home.quick" : "home.config", app)
        setToggle("config.recognition", true, app)
        setToggle("config.recall", false, app)
        setToggle("config.hiraganaOnly", false, app)
        setToggle("config.hint", true, app)
        choose("config.before", "Kanji", app)
        choose("config.after", "Kanji + Hiragana", app)
        if quick { setToggle("quick.writing", writing, app) }
    }

    @MainActor func testHeaderHasFullTitleBesideSettings() throws {
        let app = try launch()
        let title = element("home.title", app), settings = element("home.settings", app)
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Pyoko")
        XCTAssertGreaterThan(title.frame.width, title.frame.height * 1.8,
                             "The full title must not collapse into a circular toolbar item")
        XCTAssertLessThanOrEqual(title.frame.maxX, settings.frame.minX)
        XCTAssertLessThan(abs(title.frame.midY - settings.frame.midY), 12)
    }

    @MainActor func testDeckEnablementPersistsAfterRelaunch() throws {
        let app = try launch(); ensureDeck(app); tap("home.decks", app)
        tap("deck.enabled.jlpt-n5", app)
        XCTAssertEqual(element("deck.enabled.jlpt-n5", app).value as? String, "Not selected")
        restart(app); tap("home.decks", app)
        XCTAssertEqual(element("deck.enabled.jlpt-n5", app).value as? String, "Not selected")
        tap("deck.enabled.jlpt-n5", app)
        XCTAssertEqual(element("deck.enabled.jlpt-n5", app).value as? String, "Selected")
    }

    @MainActor private func checkHint(quick: Bool, writing: Bool = false) throws {
        let app = try launch(); configureCards(app, quick: quick, writing: writing)
        let hint = scrollTo("card.hint", app)
        XCTAssertFalse(element("card.hint.text", app).exists)
        hint.tap()
        let text = element("card.hint.text", app)
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        XCTAssertEqual(text.label, "たべる")
        let action = element("preview.action", app)
        XCTAssertEqual(action.label, writing ? "Check Answer" : "Show Answer",
                       "Hint must not reveal the full answer")
        hint.tap(); XCTAssertFalse(text.exists)
        scrollTo("preview.action", app).tap()
        XCTAssertEqual(action.label, "Reset Preview")
        XCTAssertFalse(hint.exists)
        action.tap(); XCTAssertTrue(hint.waitForExistence(timeout: 3))
        choose("config.before", "Hiragana", app)
        _ = scrollTo("preview.action", app)
        XCTAssertFalse(element("card.hint", app).exists)
        XCTAssertEqual(action.label, writing ? "Check Answer" : "Show Answer")
    }

    @MainActor func testReviewHintTapAndDisplayChanges() throws { try checkHint(quick: false) }
    @MainActor func testQuickHintTapAndDisplayChanges() throws { try checkHint(quick: true) }
    @MainActor func testQuickWritingHintTap() throws { try checkHint(quick: true, writing: true) }

    @MainActor func testFinalDirectionCannotBeDisabled() throws {
        let app = try launch(); configureCards(app, quick: false)
        scrollTo("config.recognition", app).tap()
        XCTAssertEqual(element("config.recognition", app).value as? String, "1")
        setToggle("config.recall", true, app); setToggle("config.recognition", false, app)
        scrollTo("config.recall", app).tap()
        XCTAssertEqual(element("config.recall", app).value as? String, "1")
    }

    @MainActor func testWidgetFiltersPreviewAndPersistence() throws {
        let app = try launch(); ensureDeck(app); tap("home.widget", app)
        setToggle("config.recognition", true, app); setToggle("config.recall", false, app)
        setToggle("config.hiraganaOnly", false, app)
        choose("config.before", "Hiragana", app); choose("config.after", "Hiragana", app)
        scrollTo("widget.source.decks", app).tap()
        scrollTo("widget.decks.none", app).tap()
        XCTAssertEqual(scrollTo("widget.count", app).label, "0 words available")
        scrollTo("widget.decks.all", app).tap()
        XCTAssertNotEqual(scrollTo("widget.count", app).label, "0 words available")
        scrollTo("widget.action", app).tap()
        XCTAssertEqual(element("widget.action", app).label, "Reset Preview")
        scrollTo("widget.preview", app).tap()
        XCTAssertEqual(element("widget.action", app).label, "Show Answer")
        scrollTo("widget.source.tags", app).tap()
        scrollTo("tags.none", app).tap()
        XCTAssertEqual(scrollTo("widget.count", app).label, "0 words available")
        scrollTo("widget.source.today", app).tap()
        XCTAssertEqual(element("widget.source.today", app).value as? String, "Selected")
        scrollTo("widget.source.all", app).tap()
        restart(app); tap("home.widget", app)
        XCTAssertEqual(scrollTo("widget.source.all", app).value as? String, "Selected")
    }

    @MainActor private func startQuick(_ app: XCUIApplication, writing: Bool = false) {
        ensureDeck(app); configureCards(app, quick: true, writing: writing)
        scrollTo("quick.source.random", app).tap()
        scrollTo("quick.start", app).tap()
    }

    @MainActor func testActualQuickRoundRetryResetAndExit() throws {
        let app = try launch(); startQuick(app)
        for _ in 0..<100 {
            if element("quick.retry", app).exists { break }
            tap("quick.reveal", app); tap("quick.incorrect", app)
        }
        tap("quick.retry", app)
        for _ in 0..<100 {
            if element("quick.reset", app).exists { break }
            tap("quick.reveal", app); tap("quick.correct", app)
        }
        XCTAssertFalse(element("quick.retry", app).exists)
        tap("quick.reset", app)
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
        tap("quick.exit", app)
        XCTAssertTrue(element("quick.start", app).waitForExistence(timeout: 5))
    }

    @MainActor func testSingleTagSelectionStartsQuickReview() throws {
        let app = try launch(); ensureDeck(app); configureCards(app, quick: true)
        scrollTo("quick.source.tags", app).tap()
        let none = scrollTo("tags.none", app)
        if none.isEnabled { none.tap() }
        XCTAssertFalse(scrollTo("quick.start", app).isEnabled)
        setToggle("tag.Noun", true, app)
        XCTAssertTrue(scrollTo("quick.start", app).isEnabled)
        restart(app); tap("home.quick", app)
        XCTAssertEqual(scrollTo("tag.Noun", app).value as? String, "1")
        scrollTo("quick.start", app).tap()
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5),
                      "A single populated tag must not lead to No Words Available")
    }

    @MainActor func testWritingRejectsBlankAndAcceptsSpaces() throws {
        let app = try launch(); startQuick(app, writing: true)
        let input = element("quick.answer", app)
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        XCTAssertFalse(element("quick.check", app).isEnabled)
        input.tap(); input.typeText("to eat")
        XCTAssertEqual(input.value as? String, "to eat")
        XCTAssertFalse(element("quick.correct", app).exists, "Typing Space must not advance")
        tap("quick.check", app); tap("quick.correct", app)
        XCTAssertTrue(element("quick.answer", app).exists || element("quick.reset", app).exists)
    }

    @MainActor private func startReview(_ app: XCUIApplication) {
        ensureDeck(app); configureCards(app, quick: false)
        restart(app); tap("home.review", app)
        #if os(macOS)
        tap("review.start", app)
        #endif
    }

    @MainActor func testActualReviewRatingsAndExit() throws {
        let app = try launch(); startReview(app)
        for rating in ["again", "hard", "good", "easy"] {
            tap("review.reveal", app); tap("review.rating.\(rating)", app)
            XCTAssertFalse(element("review.rating.\(rating)", app).exists)
        }
        tap("review.exit", app)
    }

    @MainActor func testPreviouslyReviewedSourcePersistsAndStartsAfterGrading() throws {
        let app = try launch(); startReview(app)
        tap("review.reveal", app); tap("review.rating.good", app)
        restart(app); configureCards(app, quick: true)
        scrollTo("quick.source.reviewed", app).tap()
        XCTAssertEqual(element("quick.source.reviewed", app).value as? String, "Selected")
        XCTAssertTrue(scrollTo("quick.start", app).isEnabled)
        restart(app); tap("home.quick", app)
        XCTAssertEqual(scrollTo("quick.source.reviewed", app).value as? String, "Selected")
        scrollTo("quick.start", app).tap()
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
        tap("quick.reveal", app); tap("quick.correct", app)
    }

    #if os(macOS)
    @MainActor func testMacReviewSpaceAndAllFourNumberKeys() throws {
        let app = try launch(); startReview(app)
        for (key, rating) in zip(["1", "2", "3", "4"], ["again", "hard", "good", "easy"]) {
            XCTAssertTrue(element("review.reveal", app).waitForExistence(timeout: 5))
            app.typeKey(key, modifierFlags: [])
            XCTAssertTrue(element("review.reveal", app).exists, "Cannot grade before reveal")
            app.typeKey(" ", modifierFlags: [])
            XCTAssertTrue(element("review.rating.\(rating)", app).waitForExistence(timeout: 5))
            app.typeKey(key, modifierFlags: [])
            XCTAssertFalse(element("review.rating.\(rating)", app).exists)
        }
    }

    @MainActor func testMacQuickSpaceRevealsThenAdvances() throws {
        let app = try launch(); startQuick(app)
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
        app.typeKey(" ", modifierFlags: [])
        XCTAssertTrue(element("quick.next", app).waitForExistence(timeout: 5))
        app.typeKey(" ", modifierFlags: [])
        XCTAssertFalse(element("quick.next", app).exists)
        XCTAssertTrue(element("quick.reveal", app).exists || element("quick.reset", app).exists)
    }

    @MainActor func testMacQuickThreeMarksIncorrectAndFourCorrectsRetry() throws {
        let app = try launch(); startQuick(app)
        var answered = 0
        for _ in 0..<100 {
            if element("quick.retry", app).exists { break }
            XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
            for key in ["3", "4"] { app.typeKey(key, modifierFlags: []) }
            XCTAssertTrue(element("quick.reveal", app).exists, "Number keys must not score before reveal")
            XCTAssertEqual(element("quick.score.incorrect", app).value as? String, String(answered))
            XCTAssertEqual(element("quick.score.correct", app).value as? String, "0")
            app.typeKey(" ", modifierFlags: [])
            XCTAssertTrue(element("quick.incorrect", app).waitForExistence(timeout: 5))
            app.typeKey("3", modifierFlags: [])
            answered += 1
            XCTAssertEqual(element("quick.score.incorrect", app).value as? String, String(answered))
            XCTAssertEqual(element("quick.score.correct", app).value as? String, "0")
        }
        XCTAssertGreaterThan(answered, 0)
        tap("quick.retry", app)
        for corrected in 1...answered {
            tap("quick.reveal", app)
            app.typeKey("4", modifierFlags: [])
            XCTAssertEqual(element("quick.score.correct", app).value as? String, String(corrected))
            XCTAssertEqual(element("quick.score.incorrect", app).value as? String, String(answered - corrected))
        }
        XCTAssertTrue(element("quick.reset", app).waitForExistence(timeout: 5))
        XCTAssertFalse(element("quick.retry", app).exists)
    }

    @MainActor func testMacQuickRatingKeysRemainTextInWritingMode() throws {
        let app = try launch(); startQuick(app, writing: true)
        let input = element("quick.answer", app)
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("3 4")
        XCTAssertEqual(input.value as? String, "3 4")
        XCTAssertEqual(element("quick.score.correct", app).value as? String, "0")
        XCTAssertEqual(element("quick.score.incorrect", app).value as? String, "0")
        XCTAssertFalse(element("quick.correct", app).exists)
        tap("quick.check", app)
        app.typeKey("4", modifierFlags: [])
        XCTAssertEqual(element("quick.score.correct", app).value as? String, "1")
        XCTAssertEqual(element("quick.score.incorrect", app).value as? String, "0")
    }
    #endif

    @MainActor func testSettingsPaletteControls() throws {
        let app = try launch(); tap("home.settings", app)
        XCTAssertTrue(element("settings.theme", app).waitForExistence(timeout: 10))
        for theme in ["classic", "ruby", "sunset", "forest", "ocean", "indigo", "plum", "rose", "slate", "mono"] {
            scrollTo("theme.\(theme)", app).tap()
            XCTAssertEqual(element("theme.\(theme)", app).value as? String, "Selected")
        }
        for tint in ["Blue", "Red", "Orange", "Green", "Teal", "Indigo", "Purple", "Pink", "Grey", "Charcoal"] {
            choose("settings.tint", tint, app)
        }
        for appearance in ["Light", "Dark", "System"] { choose("settings.theme", appearance, app) }
        restart(app); tap("home.settings", app)
        XCTAssertEqual(scrollTo("theme.mono", app).value as? String, "Selected")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Settings"; screenshot.lifetime = .keepAlways; add(screenshot)
    }

    @MainActor func testImportRequiresANameAndFile() throws {
        let app = try launch(); tap("home.decks", app); tap("decks.import", app)
        let name = scrollTo("import.name", app)
        name.tap(); name.typeText("Incomplete UI fixture")
        XCTAssertFalse(scrollTo("import.submit", app).isEnabled,
                       "A name alone must not enable an import")
    }

    @MainActor func testDeckDeleteCancelThenConfirmAndReinstall() throws {
        let app = try launch(); ensureDeck(app); tap("home.decks", app)
        tap("deck.delete.jlpt-n5", app)
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(element("deck.enabled.jlpt-n5", app).exists)
        tap("deck.delete.jlpt-n5", app)
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Delete"].tap()
        XCTAssertTrue(element("install.jlpt-n5", app).waitForExistence(timeout: 10))
        restart(app); ensureDeck(app)
    }
}
