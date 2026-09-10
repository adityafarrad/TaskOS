import Testing
import Foundation
@testable import TaskOSCore

@Suite("Composer document")
struct ComposerDocumentTests {
    private func firstOpenID(_ document: ComposerDocument) -> UUID {
        document.actions.first { action in
            if case .openApplication = action.draft { return true }
            return false
        }!.id
    }

    @Test func emptyDocumentHasNothing() {
        let document = ComposerDocument()
        #expect(document.actions.isEmpty)
        #expect(document.unresolvedTexts.isEmpty)
        #expect(document.parseOutcome == .needsInput)
        #expect(document.makeDefinition(name: "Test") == nil)
    }

    @Test func typingARecognizedCommandCreatesAnAction() {
        var document = ComposerDocument()
        document.setText("open Safari")

        #expect(document.actions.count == 1)
        #expect(document.unresolvedTexts.isEmpty)
        guard case .openApplication(let name, let resolved) = document.actions[0].draft else {
            Issue.record("Expected an open application action")
            return
        }
        #expect(name == "Safari")
        #expect(resolved == nil)
    }

    @Test func unsupportedSuffixIsRetainedAndBlocksDefinition() {
        var document = ComposerDocument()
        document.setText("open Safari and email Bob")

        #expect(document.actions.count == 1)
        #expect(document.unresolvedTexts == ["email Bob"])
        #expect(document.hasUnresolvedText)
        #expect(document.parseOutcome == .unsupported)
        #expect(document.makeDefinition(name: "Test") == nil)
    }

    @Test func cardEditUpdatesOnlyItsClauseAndPreservesUnresolvedText() {
        var document = ComposerDocument()
        document.setText("open Safari then email Bob")
        document.addAction(.wait(2))

        #expect(document.renderedText() == "Open Safari, then email Bob, then Wait 2 seconds")

        document.updateAction(id: firstOpenID(document), draft: .openApplication(name: "Notes", resolved: nil))

        #expect(document.renderedText() == "Open Notes, then email Bob, then Wait 2 seconds")
        #expect(document.unresolvedTexts == ["email Bob"])
    }

    @Test func resolvingAnApplicationEnablesTheDefinition() {
        var document = ComposerDocument()
        document.setText("open Safari")

        document.resolveApplication(
            id: firstOpenID(document),
            reference: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )

        let actions = document.resolvedActions()
        #expect(actions?.count == 1)
        #expect(document.makeDefinition(name: "Test") != nil)
    }

    @Test func removingAnActionRegeneratesText() {
        var document = ComposerDocument()
        document.setText("open Safari and wait 1 second")

        document.removeAction(id: firstOpenID(document))

        #expect(document.renderedText() == "Wait 1 seconds")
        #expect(document.actions.count == 1)
    }

    @Test func undoAndRedoAcrossTyping() {
        var document = ComposerDocument()
        document.setText("open Safari")
        document.setText("open Safari and wait 2 seconds")

        #expect(document.actions.count == 2)

        document.undo()
        #expect(document.renderedText() == "Open Safari")

        document.undo()
        #expect(document.renderedText() == "")

        document.redo()
        #expect(document.renderedText() == "Open Safari")
    }

    @Test func undoAndRedoAcrossCardRemoval() {
        var document = ComposerDocument()
        document.setText("open Safari and wait 2 seconds")
        let openID = firstOpenID(document)

        document.removeAction(id: openID)
        #expect(document.actions.count == 1)

        document.undo()
        #expect(document.actions.count == 2)

        document.redo()
        #expect(document.actions.count == 1)
    }

    @Test func acceptingASuggestionReplacesTheTrailingFragment() {
        var document = ComposerDocument()
        document.setText("open Sa")

        let suggestion = Suggestion(
            id: "app.com.apple.Safari",
            phrase: "Open Safari",
            title: "Safari",
            category: .application,
            requiresParameter: false,
            match: .prefix
        )
        document.accept(suggestion)

        #expect(document.text == "Open Safari")
        #expect(document.actions.count == 1)
    }

    @Test func movingActionsReordersText() {
        var document = ComposerDocument()
        document.setText("open Safari and wait 1 second and show a notification")
        let openID = firstOpenID(document)

        document.moveActionDown(id: openID)

        #expect(document.renderedText() == "Wait 1 seconds, then Open Safari, then Show a notification")
    }
}
