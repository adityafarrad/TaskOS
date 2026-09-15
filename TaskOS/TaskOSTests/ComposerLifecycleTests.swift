import Testing
import Foundation
import TaskOSCore
@testable import TaskOS

@MainActor
@Suite("Composer draft and preview lifecycle", .serialized)
struct ComposerLifecycleTests {
    private let composition = AppComposition.shared

    @Test func draftClearsThroughDiscardNewAndSave() async throws {
        let model = ComposerViewModel()

        try await composition.drafts.saveDraft(ComposerDraft(name: "D", text: "open Safari"))
        model.discardRecoverableDraft()
        #expect(await waitForDraftCleared())

        try await composition.drafts.saveDraft(ComposerDraft(name: "D", text: "open Safari"))
        model.newWorkflow()
        #expect(await waitForDraftCleared())

        try await composition.drafts.saveDraft(ComposerDraft(name: "D", text: "wait 1 second"))
        model.updateFromEditor(text: "wait 1 second", edit: nil)
        await model.save()
        #expect(await waitForDraftCleared())
    }

    @Test func previewPublishesWithoutStartingARun() async throws {
        let history = composition.runHistory
        let before = try await history.recentRuns(limit: 10_000).count

        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 0.1 seconds", edit: nil)
        model.prepare()

        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if case .previewed = model.stage { break }
            try? await Task.sleep(for: .milliseconds(25))
        }

        guard case .previewed = model.stage else {
            Issue.record("Preview was not published")
            return
        }
        if case .running = model.stage {
            Issue.record("Preview must not start a run")
        }
        let after = try await history.recentRuns(limit: 10_000).count
        #expect(after == before)
    }

    private func waitForDraftCleared(timeout: TimeInterval = 3) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (try? await composition.drafts.loadDraft()) == nil {
                return true
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return (try? await composition.drafts.loadDraft()) == nil
    }
}
