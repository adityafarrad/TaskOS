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
        XCTAssertTrue(element(app, "editor.title").exists)
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
        XCTAssertTrue(element(app, "editor.view").waitForExistence(timeout: 5))
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
    }
}
