import AppKit
import XCTest

final class TaskOSUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launch()
        app.activate()
        return app
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private func composerField(_ app: XCUIApplication) -> XCUIElement {
        let textField = app.textFields["composer.field"]
        if textField.exists {
            return textField
        }
        return app.textViews["composer.field"]
    }

    @MainActor
    func testLaunchShowsEditor() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))
        XCTAssertFalse(
            element(app, "editor.title").exists,
            "An empty new workflow should not show the title chrome"
        )
        XCTAssertTrue(element(app, "editor.run").exists)
    }

    @MainActor
    func testSidebarNavigationSwitchesDestinations() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        element(app, "sidebar.templates").click()
        XCTAssertTrue(element(app, "templates.view").waitForExistence(timeout: 5))

        element(app, "sidebar.history").click()
        XCTAssertTrue(element(app, "history.view").waitForExistence(timeout: 5))

        element(app, "sidebar.settings").click()
        XCTAssertTrue(element(app, "settings.view").waitForExistence(timeout: 5))

        element(app, "sidebar.workflows").click()
        XCTAssertTrue(element(app, "workflows.view").waitForExistence(timeout: 5))
    }

    @MainActor
    func testComposerTypingCreatesAStep() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        app.activate()
        XCTAssertEqual(app.state, .runningForeground)

        let composer = composerField(app)
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertTrue(composer.isHittable, "composer should be hittable")

        composer.click()
        Thread.sleep(forTimeInterval: 0.4)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("wait 1 second", forType: .string)
        composer.typeKey("v", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)

        XCTAssertEqual(composer.value as? String, "wait 1 second")
        XCTAssertTrue(app.staticTexts["1 step"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNewWorkflowShowsSuggestions() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        element(app, "sidebar.workflows").click()
        XCTAssertTrue(element(app, "workflows.view").waitForExistence(timeout: 5))

        element(app, "sidebar.newWorkflow").click()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 5))

        let suggestion = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Arrange a window"))
            .firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "New workflow should offer suggestions like first launch")
    }

    @MainActor
    func testAddStepMenuCreatesAStep() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))
        XCTAssertTrue(element(app, "composer.field").exists, "composer field should be visible")

        element(app, "editor.view").swipeUp()
        let addStep = element(app, "editor.addStep")
        XCTAssertTrue(addStep.waitForExistence(timeout: 5))
        if !addStep.isHittable {
            element(app, "editor.view").swipeUp()
        }
        addStep.click()
        let waitItem = app.menuItems["Wait 1 second"]
        XCTAssertTrue(waitItem.waitForExistence(timeout: 5))
        waitItem.click()

        XCTAssertTrue(app.staticTexts["1 step"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDiscoverySheetOpensAndCloses() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        element(app, "editor.capabilities").click()
        XCTAssertTrue(app.staticTexts["Supported actions and triggers"].waitForExistence(timeout: 5))

        element(app, "discovery.done").click()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsShowsStartupRow() throws {
        let app = launchApp()
        element(app, "sidebar.settings").click()
        XCTAssertTrue(app.staticTexts["Launch TaskOS at login"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Run automatic triggers"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDiscoveryAddStepCreatesAStep() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        element(app, "editor.capabilities").click()
        XCTAssertTrue(app.staticTexts["Supported actions and triggers"].waitForExistence(timeout: 5))

        let search = element(app, "discovery.search")
        search.click()
        Thread.sleep(forTimeInterval: 0.3)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Wait", forType: .string)
        search.typeKey("v", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)

        let addButton = app.buttons["Add Step"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertTrue(addButton.isHittable, "filtered Add Step should be reachable")
        addButton.click()

        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, "step.card.0").waitForExistence(timeout: 5))
    }

    @MainActor
    func testStepMenuOffersDuplicate() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("wait 1 second", forType: .string)
        let composer = element(app, "composer.field")
        composer.click()
        Thread.sleep(forTimeInterval: 0.4)
        composer.typeKey("v", modifierFlags: .command)

        XCTAssertTrue(element(app, "step.card.0").waitForExistence(timeout: 5))
        element(app, "step.menu.0").click()
        XCTAssertTrue(app.menuItems["Duplicate"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testReturnAcceptsHighlightedSuggestion() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "open")

        let suggestion = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Open an application"))
            .firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))

        composer.typeKey(.return, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.6)

        let value = composer.value as? String
        XCTAssertNotEqual(value, "open", "Return should accept the highlighted suggestion")
        XCTAssertFalse((value ?? "").isEmpty)
        XCTAssertFalse(
            app.staticTexts["Review workflow"].exists,
            "Return must not open the review or start a run"
        )
    }

    @MainActor
    func testEscapeDismissesSuggestions() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "open")

        let suggestion = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Open an application"))
            .firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))

        composer.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(waitForDisappearance(suggestion))
        XCTAssertFalse(app.staticTexts["Review workflow"].exists)
    }

    @MainActor
    func testTabAcceptsOnlyAfterExplicitSelection() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "open")

        let suggestion = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Open an application"))
            .firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5))

        composer.typeKey(.downArrow, modifierFlags: [])
        composer.typeKey(.tab, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.6)

        let value = composer.value as? String
        XCTAssertNotEqual(value, "open", "Tab should accept after an explicit selection")
        XCTAssertFalse((value ?? "").isEmpty)
        XCTAssertFalse(app.staticTexts["Review workflow"].exists)
    }

    @MainActor
    func testPendingSecondActionKeepsTypedText() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "open safari then open")
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertEqual(composer.value as? String, "open safari then open")
    }

    @MainActor
    func testColloquialDailyPhraseCreatesAStep() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "at 9:00 pm open notes everyday")
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.staticTexts["1 step"].waitForExistence(timeout: 5))
        let unresolved = app.staticTexts
            .matching(
                NSPredicate(
                    format: "label BEGINSWITH %@ OR value BEGINSWITH %@",
                    "Unresolved:", "Unresolved:"
                )
            )
            .firstMatch
        XCTAssertFalse(unresolved.exists)
    }

    @MainActor
    func testDailyScheduleFirstCompletes() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "at 9:00 am open notes everyday")
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertTrue(app.staticTexts["1 step"].waitForExistence(timeout: 5))
        let unresolved = app.staticTexts
            .matching(
                NSPredicate(
                    format: "label BEGINSWITH %@ OR value BEGINSWITH %@",
                    "Unresolved:", "Unresolved:"
                )
            )
            .firstMatch
        XCTAssertFalse(unresolved.exists)
    }

    @MainActor
    func testPartialScheduleActionCanBeCompleted() throws {
        let app = launchApp()
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 10))

        let composer = composerField(app)
        pasteComposerText(app, "at 9:00 am open")
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertEqual(composer.value as? String, "at 9:00 am open")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(" notes everyday", forType: .string)
        composer.typeKey("v", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertEqual(composer.value as? String, "at 9:00 am open notes everyday")
        XCTAssertTrue(app.staticTexts["1 step"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func pasteComposerText(_ app: XCUIApplication, _ text: String) {
        let composer = composerField(app)
        composer.click()
        Thread.sleep(forTimeInterval: 0.4)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        composer.typeKey("v", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.4)
    }

    @MainActor
    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = expectation(for: predicate, evaluatedWith: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
