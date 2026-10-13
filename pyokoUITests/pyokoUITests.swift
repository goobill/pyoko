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
        XCTAssertEqual(action.label, writing ? "Check" : "Show Answer",
                       "Hint must not reveal the full answer")
        hint.tap(); XCTAssertFalse(text.exists)
        scrollTo("preview.action", app).tap()
        XCTAssertEqual(action.label, "Reset Preview")
        XCTAssertFalse(hint.exists)
        action.tap(); XCTAssertTrue(hint.waitForExistence(timeout: 3))
        choose("config.before", "Hiragana", app)
        _ = scrollTo("preview.action", app)
        XCTAssertFalse(element("card.hint", app).exists)
        XCTAssertEqual(action.label, writing ? "Check" : "Show Answer")
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
        XCTAssertFalse(element("quick.unsure", app).exists, "Unsure belongs to writing mode")
        for _ in 0..<100 {
            if element("quick.retry", app).exists { break }
            tap("quick.reveal", app); tap("quick.incorrect", app)
        }
        #if os(macOS)
        XCTAssertTrue(element("completion.desktop", app).exists)
        XCTAssertGreaterThanOrEqual(scrollTo("quick.retry", app).frame.height, 44)
        XCTAssertGreaterThanOrEqual(scrollTo("quick.reset", app).frame.height, 44)
        XCTAssertGreaterThanOrEqual(scrollTo("quick.complete.exit", app).frame.height, 44)
        #endif
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

    @MainActor func testQuickStartStaysPinnedWhileSettingsScroll() throws {
        let app = try launch(); ensureDeck(app); configureCards(app, quick: true)
        scrollTo("quick.source.random", app).tap()
        let start = element("quick.start", app)
        XCTAssertTrue(start.isHittable)
        let initialY = start.frame.midY
        let scroll = app.scrollViews["config.scroll"]
        #if os(macOS)
        scroll.scroll(byDeltaX: 0, deltaY: 500)
        #else
        scroll.swipeDown()
        #endif
        XCTAssertTrue(start.isHittable)
        XCTAssertEqual(start.frame.midY, initialY, accuracy: 2)
        #if os(macOS)
        scroll.scroll(byDeltaX: 0, deltaY: -500)
        #else
        scroll.swipeUp()
        #endif
        XCTAssertTrue(start.isHittable)
        XCTAssertEqual(start.frame.midY, initialY, accuracy: 2)
        start.tap()
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
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

    #if os(iOS)
    @MainActor func testPhoneWritingKeepsFocusAcrossEditsAndNextCard() throws {
        let app = try launch(); startQuick(app, writing: true)
        for _ in 0..<2 {
            let input = element("quick.answer", app)
            XCTAssertTrue(input.waitForExistence(timeout: 10))
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5),
                          "Writing should focus automatically; enable the simulator software keyboard")
            var expected = ""
            for character in ["t", "o", " ", "e", "a", "t"] {
                // Never tap the field: refocusing would mask this regression.
                app.typeText(character)
                expected += character
                XCTAssertEqual(input.value as? String, expected)
                XCTAssertTrue(app.keyboards.firstMatch.exists, "Typing must not dismiss the keyboard")
            }
            app.typeText(XCUIKeyboardKey.delete.rawValue)
            XCTAssertEqual(input.value as? String, "to ea")
            let check = element("quick.check", app)
            let unsure = element("quick.unsure", app)
            let card = element("quick.card", app)
            let keyboardTop = app.keyboards.firstMatch.frame.minY
            XCTAssertEqual(check.label, "Check")
            XCTAssertEqual(unsure.label, "Unsure")
            XCTAssertTrue(check.isHittable && unsure.isHittable && input.isHittable,
                          "Writing actions must be reachable without scrolling")
            XCTAssertLessThanOrEqual(input.frame.maxY, keyboardTop)
            XCTAssertLessThanOrEqual(check.frame.maxY, keyboardTop)
            XCTAssertLessThanOrEqual(unsure.frame.maxY, keyboardTop)
            XCTAssertLessThan(unsure.frame.midX, check.frame.midX)
            XCTAssertLessThan(abs(check.frame.midY - unsure.frame.midY), 4)
            XCTAssertLessThanOrEqual(card.frame.height, 221,
                                     "Writing must use a compact question card")
            app.typeText("t\n")
            XCTAssertTrue(element("quick.correct", app).waitForExistence(timeout: 5))
            XCTAssertFalse(input.exists, "Return should reveal the answer")
            tap("quick.correct", app)
            if element("quick.reset", app).exists { tap("quick.reset", app) }
        }
    }

    @MainActor func testPhoneNonWritingDoesNotOpenKeyboard() throws {
        let app = try launch(); startQuick(app, writing: false)
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertFalse(element("quick.answer", app).exists)
    }
    #endif

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

    @MainActor func testWritingUnsureRevealsBlankAnswerWithoutScoring() throws {
        let app = try launch(); startQuick(app, writing: true)
        #if os(macOS)
        XCTAssertTrue(element("study.desktop", app).waitForExistence(timeout: 5))
        #else
        XCTAssertTrue(element("study.phone", app).waitForExistence(timeout: 5))
        #endif
        XCTAssertFalse(element("quick.check", app).isEnabled)
        let unsure = scrollTo("quick.unsure", app)
        XCTAssertTrue(unsure.isHittable)
        unsure.tap()
        XCTAssertFalse(element("quick.answer", app).exists)
        XCTAssertFalse(element("quick.unsure", app).exists)
        XCTAssertEqual(element("quick.score.correct", app).value as? String, "0")
        XCTAssertEqual(element("quick.score.incorrect", app).value as? String, "0")
        scrollTo("quick.incorrect", app).tap()
        XCTAssertEqual(element("quick.score.incorrect", app).value as? String, "1")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Platform study layout"; screenshot.lifetime = .keepAlways; add(screenshot)
        if element("quick.reset", app).exists { tap("quick.reset", app) }
        XCTAssertTrue(scrollTo("quick.unsure", app).isHittable, "Each writing card must allow Unsure")
    }

    @MainActor func testWritingPreviewUnsurePreservesAttemptAndResets() throws {
        let app = try launch(); configureCards(app, quick: true, writing: true)
        let input = scrollTo("preview.answer", app)
        input.tap(); input.typeText("my attempt")
        scrollTo("preview.unsure", app).tap()
        XCTAssertTrue(app.staticTexts["my attempt"].exists)
        XCTAssertEqual(element("preview.action", app).label, "Reset Preview")
        scrollTo("preview.action", app).tap()
        XCTAssertTrue(element("preview.answer", app).exists)
        XCTAssertTrue(element("preview.unsure", app).exists)
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
    @MainActor func testMacScheduledCompletionUsesLargeActionsAndExits() throws {
        let app = try launch(); startReview(app)
        for _ in 0..<100 {
            if element("review.complete.exit", app).exists { break }
            scrollTo("review.reveal", app).tap()
            scrollTo("review.rating.easy", app).tap()
        }
        XCTAssertTrue(element("completion.desktop", app).exists)
        let exit = scrollTo("review.complete.exit", app)
        XCTAssertGreaterThanOrEqual(exit.frame.height, 44)
        XCTAssertFalse(element("review.checkAgain", app).exists)
        XCTAssertTrue(element("review.complete.metric.Completed", app).exists)
        XCTAssertTrue(element("review.complete.metric.Due now", app).exists)
        for id in ["review.extend"] where element(id, app).exists {
            XCTAssertGreaterThanOrEqual(scrollTo(id, app).frame.height, 44)
        }
        exit.tap()
        XCTAssertTrue(element("review.start", app).waitForExistence(timeout: 5))
    }

    @MainActor func testMacWritingAutofocusEnterAndGradeWithoutClickingField() throws {
        let app = try launch(); startQuick(app, writing: true)
        for attempt in 0..<2 {
            let input = element("quick.answer", app)
            XCTAssertTrue(input.waitForExistence(timeout: 5))
            app.typeText("answer 3 4")
            XCTAssertEqual(input.value as? String, "answer 3 4",
                           "The new writing field must accept typing without a click")
            app.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
            XCTAssertTrue(element("quick.correct", app).waitForExistence(timeout: 5))
            app.typeKey(attempt == 0 ? "4" : "3", modifierFlags: [])
            XCTAssertFalse(element("quick.correct", app).exists)
            if attempt == 0 && element("quick.reset", app).exists {
                tap("quick.reset", app)
            }
        }
    }

    @MainActor func testMacWritingComparisonAndInlineShortcutHelp() throws {
        let app = try launch(); startQuick(app, writing: true)
        let help = element("shortcuts.help", app)
        let progress = element("study.progress", app)
        XCTAssertTrue(help.waitForExistence(timeout: 5))
        XCTAssertTrue(progress.exists)
        XCTAssertEqual(help.frame.midY, progress.frame.midY, accuracy: 4)
        XCTAssertEqual(help.label, "Shortcuts")
        XCTAssertGreaterThan(help.frame.minX, progress.frame.maxX)
        let check = scrollTo("quick.check", app)
        let unsure = element("quick.unsure", app)
        XCTAssertTrue(unsure.exists)
        XCTAssertEqual(check.frame.midY, unsure.frame.midY, accuracy: 2)
        XCTAssertGreaterThan(check.frame.minX, unsure.frame.maxX)
        XCTAssertFalse(check.isEnabled)
        XCTAssertTrue(unsure.isEnabled)
        scrollTo("quick.unsure", app).tap()
        let correct = scrollTo("writing.correctAnswer", app)
        let attempt = element("writing.yourAnswer", app)
        XCTAssertTrue(attempt.exists)
        XCTAssertEqual(correct.frame.minY, attempt.frame.minY, accuracy: 2)
        XCTAssertGreaterThan(attempt.frame.minX, correct.frame.maxX)
        XCTAssertTrue(app.staticTexts["—"].exists, "A blank attempt has a visible placeholder")
        tap("quick.exit", app)
        XCTAssertTrue(element("quick.start", app).waitForExistence(timeout: 5),
                      "The lower back control must still return to config")
    }

    @MainActor func testMacReviewControlsStayBelowCardInOneRow() throws {
        let app = try launch(); startReview(app)
        let reveal = scrollTo("review.reveal", app)
        XCTAssertLessThanOrEqual(reveal.frame.height, 52)
        XCTAssertGreaterThanOrEqual(reveal.frame.minY, element("study.card", app).frame.maxY)
        reveal.tap()
        let ratings = ["again", "hard", "good", "easy"].map { element("review.rating.\($0)", app) }
        _ = scrollTo("review.rating.again", app)
        for rating in ratings {
            XCTAssertTrue(rating.exists)
            XCTAssertEqual(rating.frame.midY, ratings[0].frame.midY, accuracy: 2)
            XCTAssertGreaterThanOrEqual(rating.frame.minY, element("study.card", app).frame.maxY)
        }
        for index in 1..<ratings.count {
            XCTAssertGreaterThan(ratings[index].frame.minX, ratings[index - 1].frame.maxX)
        }
        ratings[2].tap()
        restart(app)
        XCTAssertTrue(element("review.summary.completed", app).waitForExistence(timeout: 5))
        XCTAssertGreaterThan(Int(element("review.summary.completed", app).value as? String ?? "") ?? 0, 0)
        XCTAssertGreaterThanOrEqual(element("review.start", app).frame.height, 40)
    }

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

    @MainActor func testMacShortcutHelpOpensAndClosesInConfigAndStudy() throws {
        let app = try launch(); ensureDeck(app); configureCards(app, quick: true)
        scrollTo("shortcuts.help", app).tap()
        XCTAssertTrue(app.staticTexts["Again / Hard / Good / Easy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Incorrect / Correct"].exists)
        tap("shortcuts.done", app)
        XCTAssertFalse(element("shortcuts.done", app).exists)
        scrollTo("quick.source.random", app).tap()
        scrollTo("quick.start", app).tap()
        tap("shortcuts.help", app)
        XCTAssertTrue(app.staticTexts["Writing mode"].waitForExistence(timeout: 5))
        tap("shortcuts.done", app)
        tap("quick.reveal", app)
        XCTAssertGreaterThanOrEqual(element("quick.correct", app).frame.height, 44)
        XCTAssertGreaterThanOrEqual(element("quick.incorrect", app).frame.height, 44)
    }

    @MainActor func testMacTagSearchKeepsHiddenSelectionsAndPersists() throws {
        let app = try launch(); ensureDeck(app); configureCards(app, quick: true)
        scrollTo("quick.source.tags", app).tap()
        let none = scrollTo("tags.none", app)
        if none.isEnabled { none.tap() }
        let search = scrollTo("tags.search", app)
        search.tap(); search.typeText("noun")
        setToggle("tag.Noun", true, app)
        search.tap(); app.typeKey("a", modifierFlags: .command)
        search.typeText("no-such-pyoko-tag")
        XCTAssertTrue(app.staticTexts["No tags match your search."].exists)
        XCTAssertFalse(element("tag.Noun", app).exists)
        search.tap(); app.typeKey("a", modifierFlags: .command)
        app.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])
        XCTAssertEqual(scrollTo("tag.Noun", app).value as? String, "1")
        restart(app); tap("home.quick", app)
        XCTAssertEqual(scrollTo("tag.Noun", app).value as? String, "1")
        scrollTo("quick.start", app).tap()
        XCTAssertTrue(element("quick.reveal", app).waitForExistence(timeout: 5))
    }

    @MainActor func testMacWideConfigUsesSeparateColumns() throws {
        let app = try launch(); tap("home.config", app)
        let controls = element("config.controls", app)
        XCTAssertTrue(controls.waitForExistence(timeout: 5))
        try XCTSkipUnless(element("config.columns", app).exists,
                          "Enlarge the Mac window until the detail area is at least 860 points, then rerun.")
        let preview = element("config.previews", app)
        XCTAssertTrue(preview.exists)
        XCTAssertGreaterThanOrEqual(preview.frame.minX - controls.frame.maxX, 20)
        XCTAssertLessThanOrEqual(preview.frame.width, 620)
        XCTAssertGreaterThanOrEqual(controls.frame.width, 360)
    }

    @MainActor func testMacLockPreviewIsCenteredInItsPanel() throws {
        let app = try launch(); tap("home.widget", app)
        let preview = scrollTo("widget.lockPreview", app)
        let panel = element("widget.lockPanel", app)
        XCTAssertTrue(panel.exists)
        XCTAssertEqual(preview.frame.midX, panel.frame.midX, accuracy: 4)
        XCTAssertLessThanOrEqual(preview.frame.width, 220,
                                 "The lock preview must retain accessory proportions")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Mac widget configuration"; screenshot.lifetime = .keepAlways; add(screenshot)
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
        let app = try launch(); tap("home.decks", app)
        XCTAssertTrue(scrollTo("decks.more", app).isHittable)
        tap("decks.import", app)
        XCTAssertTrue(scrollTo("decks.more", app).isHittable)
        #if os(macOS)
        XCTAssertTrue(element("import.desktop", app).waitForExistence(timeout: 5))
        #endif
        let name = scrollTo("import.name", app)
        name.tap(); name.typeText("Incomplete UI fixture")
        XCTAssertFalse(scrollTo("import.submit", app).isEnabled,
                       "A name alone must not enable an import")
    }

    @MainActor func testRandomWidgetModeAndPairsPersist() throws {
        let app = try launch(); ensureDeck(app); tap("home.widget", app)
        let mode = scrollTo("widget.mode", app)
        #if os(macOS)
        mode.radioButtons["Random"].tap()
        #else
        mode.buttons["Random"].tap()
        #endif
        for pair in ["Kanji + English", "Hiragana + English", "Kanji + Hiragana"] {
            choose("widget.pair", pair, app)
            XCTAssertEqual(scrollTo("widget.action", app).label, "Next Word")
            scrollTo("widget.action", app).tap()
            XCTAssertEqual(element("widget.action", app).label, "Next Word")
        }
        restart(app); tap("home.widget", app)
        XCTAssertTrue(scrollTo("widget.pair", app).exists)
        XCTAssertEqual(scrollTo("widget.action", app).label, "Next Word")
        let restoredMode = scrollTo("widget.mode", app)
        #if os(macOS)
        restoredMode.radioButtons["Review"].tap()
        #else
        restoredMode.buttons["Review"].tap()
        #endif
        XCTAssertEqual(scrollTo("widget.action", app).label, "Show Answer")
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
