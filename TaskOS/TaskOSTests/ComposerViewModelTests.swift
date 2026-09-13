import Foundation
import Testing
import TaskOSCore
@testable import TaskOS

@MainActor
@Suite("Composer view model presentation")
struct ComposerViewModelTests {
    @Test func duplicateActionInsertsCopyAfterOriginal() {
        let model = ComposerViewModel()
        model.add(.wait(1))
        model.add(.wait(2))

        let firstID = model.actions[0].id
        model.duplicateAction(id: firstID)

        #expect(model.actions.count == 3)
        #expect(model.actions[1].id != firstID)
        guard case .wait(let duration) = model.actions[1].draft else {
            Issue.record("expected the duplicate to be a wait, got \(model.actions[1].draft)")
            return
        }
        #expect(duration == 1)
    }

    @Test func moveActionsReordersSteps() {
        let model = ComposerViewModel()
        model.add(.wait(1))
        model.add(.wait(2))
        model.add(.wait(3))

        model.moveActions(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(model.actions.map(\.draft) == [.wait(3), .wait(1), .wait(2)])
    }

    @Test func hasUnsavedChangesTracksEdits() {
        let model = ComposerViewModel()
        #expect(!model.hasUnsavedChanges)

        model.add(.wait(1))
        #expect(model.hasUnsavedChanges)
    }

    @Test func newWorkflowClearsTheDocument() {
        let model = ComposerViewModel()
        model.add(.wait(1))
        #expect(model.hasUnsavedChanges)

        model.newWorkflow()
        #expect(model.actions.isEmpty)
        #expect(!model.hasUnsavedChanges)
        #expect(!model.isRunning)
    }

    @Test func resolveApplicationUpdatesTheStepSummary() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "an application", resolved: nil))
        let id = model.actions[0].id

        model.resolve(id: id, application: ApplicationResource(bundleIdentifier: "net.whatsapp.WhatsApp", displayName: "WhatsApp"))

        guard case .openApplication(_, let resolved) = model.actions[0].draft else {
            Issue.record("expected open application")
            return
        }
        #expect(resolved?.label == "WhatsApp")
    }

    @Test func editorEditUpdatesTextAndSelection() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)
        #expect(model.text == "wait 1 second")
        #expect(model.actions.count == 1)

        let edit = CommandEdit(
            range: SourceSpan(start: 5, end: 6),
            replacement: "2",
            resultingSelection: SourceSpan(start: 6, end: 6)
        )
        model.updateFromEditor(text: "wait 2 second", edit: edit)
        #expect(model.text == "wait 2 second")
        #expect(model.commandSelection == SourceSpan(start: 6, end: 6))
    }

    @Test func markedTextSuspendsCompletion() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open", edit: nil)
        #expect(!model.visibleSuggestions.isEmpty)

        model.setMarkedTextActive(true)
        #expect(model.visibleSuggestions.isEmpty)
        #expect(!model.acceptHighlightedInteractively())
        #expect(!model.moveHighlightInteractively(by: 1))

        model.setMarkedTextActive(false)
        #expect(!model.visibleSuggestions.isEmpty)
    }

    @Test func tabAcceptsOnlyAfterExplicitSelection() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open", edit: nil)

        #expect(!model.acceptSelectedInteractively())
        #expect(model.moveHighlightInteractively(by: 1))
        #expect(model.acceptSelectedInteractively())
    }

    @Test func staleCompletionIsRejectedAfterCursorMove() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open", edit: nil)

        guard let suggestion = model.visibleSuggestions.first else {
            Issue.record("Expected a suggestion")
            return
        }

        model.updateCommandSelection(SourceSpan(start: 2, end: 2))
        model.accept(suggestion)
        #expect(model.text == "open")
    }

    @Test func stalePreparationDoesNotPublishAPreview() async {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)

        model.prepare()
        model.updateFromEditor(text: "wait 2 seconds", edit: nil)

        try? await Task.sleep(for: .milliseconds(250))

        if case .previewed = model.stage {
            Issue.record("A stale preparation must not publish a preview")
        }
    }

    @Test func staleResourceSelectionDoesNotBind() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "Safari", resolved: nil))
        let id = model.actions[0].id

        model.updateFromEditor(text: "wait 1 second", edit: nil)
        model.resolve(
            id: id,
            application: ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari")
        )

        #expect(!model.actions.contains { $0.id == id })
    }
}
