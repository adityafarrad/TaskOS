import Testing
import Foundation
@testable import TaskOSCore

@Suite("Composer value preservation")
struct ComposerValuePreservationTests {
    private func resolveWhatsApp(_ document: inout ComposerDocument, id: UUID) {
        document.resolveApplication(
            id: id,
            reference: .application(bundleIdentifier: "net.whatsapp.WhatsApp", label: "WhatsApp")
        )
    }

    @Test func resolvingApplicationSurvivesFileChoiceOnAnotherAction() {
        var document = ComposerDocument()
        document.setText("Open an application")
        document.addAction(.revealInFinder(target: nil))

        guard document.actions.count == 2 else {
            Issue.record("expected 2 actions, got \(document.actions.count): \(document.actions.map(\.draft))")
            return
        }

        resolveWhatsApp(&document, id: document.actions[0].id)
        guard case .openApplication(_, let resolved) = document.actions[0].draft else {
            Issue.record("first action changed type")
            return
        }
        #expect(resolved?.label == "WhatsApp")

        let folder = FileTarget(kind: .folder, displayName: "Documents", path: "/Users/x/Documents")
        document.updateAction(id: document.actions[1].id, draft: .revealInFinder(target: folder))

        guard case .openApplication(_, let resolvedAfter) = document.actions[0].draft else {
            Issue.record("first action changed type after file choice")
            return
        }
        #expect(resolvedAfter?.label == "WhatsApp")
    }

    @Test func resolvingApplicationSurvivesTextFieldResync() {
        var document = ComposerDocument()
        document.setText("Open an application")
        document.addAction(.revealInFinder(target: nil))

        resolveWhatsApp(&document, id: document.actions[0].id)
        document.setText(document.renderedText())

        guard case .openApplication(_, let resolvedAfter) = document.actions[0].draft else {
            Issue.record("first action changed type after resync")
            return
        }
        #expect(resolvedAfter?.label == "WhatsApp", "resolved app lost on text resync")
    }

    @Test func resolvedAppSurvivesReorderThenStaleTextWrite() {
        var document = ComposerDocument()
        document.setText("Open an application")
        document.addAction(.revealInFinder(target: nil))

        resolveWhatsApp(&document, id: document.actions[0].id)
        let folder = FileTarget(kind: .folder, displayName: "Documents", path: "/Users/x/Documents")
        document.updateAction(id: document.actions[1].id, draft: .revealInFinder(target: folder))

        document.moveActions(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        document.setText("Open an application, then Reveal the selected item")

        var resolvedLabel: String?
        for action in document.actions {
            if case .openApplication(_, let resolved) = action.draft {
                resolvedLabel = resolved?.label
            }
        }
        #expect(resolvedLabel == "WhatsApp", "resolved app lost after reorder + stale write; actions=\(document.actions.map(\.draft))")
    }
}
