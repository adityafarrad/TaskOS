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
}
