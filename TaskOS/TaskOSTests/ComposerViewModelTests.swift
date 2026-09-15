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

    @Test func unresolvedTextCountsAsUnsavedChanges() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "do the thing", edit: nil)
        #expect(model.hasUnsavedChanges)
    }

    @Test func savePersistsUnderTheDocumentIdentityAndRebasesRevision() async throws {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)
        let identity = model.currentAutomationID

        #expect(await model.save())
        #expect(model.currentAutomationID == identity)
        #expect(!model.hasUnsavedChanges)

        let saved = try await AppComposition.shared.repository.loadAll()
        #expect(saved.first { $0.id == identity } != nil)
        #expect(saved.first { $0.id == identity }?.definition.revision == model.currentRevision)

        model.updateFromEditor(text: "wait 2 seconds", edit: nil)
        #expect(await model.save())
        let reloaded = try await AppComposition.shared.repository.loadAll()
        #expect(reloaded.first { $0.id == identity }?.definition.revision == model.currentRevision)
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

        let key = model.beginApplicationSelection(for: id)
        #expect(model.resolve(
            id: id,
            application: ApplicationResource(bundleIdentifier: "net.whatsapp.WhatsApp", displayName: "WhatsApp"),
            key: key
        ))

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

    @Test func preparationDoesNotPublishAfterDocumentReplacement() async {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)

        model.prepare()
        model.newWorkflow()

        try? await Task.sleep(for: .milliseconds(250))

        if case .previewed = model.stage {
            Issue.record("A stale preparation must not publish after replacing the document")
        }
    }

    @Test func saveDoesNotApplyStaleBookkeepingAfterDocumentReplacement() async {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)

        await model.save()
        model.newWorkflow()

        try? await Task.sleep(for: .milliseconds(400))

        #expect(!model.hasUnsavedChanges)
    }

    @Test func acceptingASuggestionMidTextPreservesTheSuffix() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open Safari and wait 30 seconds", edit: nil)
        model.updateCommandSelection(SourceSpan(start: 20, end: 20))

        guard let suggestion = model.visibleSuggestions.first(where: { $0.phrase == "Wait 1 second" }) else {
            Issue.record("Expected a wait suggestion at the caret")
            return
        }
        model.accept(suggestion)

        #expect(model.text == "open Safari and Wait 1 second 30 seconds")
        #expect(model.commandSelection == SourceSpan(start: 29, end: 29))
    }

    @Test func triggerFirstTextOffersActionCompletions() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: [
                ApplicationRecord(bundleIdentifier: "com.apple.Notes", displayName: "Notes", fileName: "Notes"),
            ]
        ))
        model.updateFromEditor(text: "at 9:00 am open no", edit: nil)

        guard let suggestion = model.visibleSuggestions.first(where: { $0.title == "Notes" }) else {
            Issue.record("Expected a Notes suggestion after the trigger prefix")
            return
        }
        model.accept(suggestion)
        #expect(model.text == "at 9:00 am Open Notes")
    }

    @Test func tomorrowScheduleIsReadyAndPastTodayBlocks() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: [
                ApplicationRecord(bundleIdentifier: "com.apple.Notes", displayName: "Notes", fileName: "Notes"),
            ]
        ))

        model.updateFromEditor(text: "tomorrow at 9:00 am open Notes", edit: nil)
        #expect(model.canPrepare)
        #expect(model.blockingReason == nil)

        model.updateFromEditor(text: "today at 12:00 am open Notes", edit: nil)
        #expect(!model.canPrepare)
        #expect(model.blockingReason?.contains("passed") == true)
    }

    @Test func blockingReasonSurfacesTheParserMessage() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open", edit: nil)
        #expect(model.blockingReason == "Open needs an application name.")
    }

    @Test func staleResourceSelectionDoesNotBind() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "Safari", resolved: nil))
        let id = model.actions[0].id
        let key = model.beginApplicationSelection(for: id)

        model.updateFromEditor(text: "wait 1 second", edit: nil)

        #expect(!model.resolve(
            id: id,
            application: ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari"),
            key: key
        ))
        #expect(!model.actions.contains { $0.id == id })
    }

    @Test func resourceSelectionRefusesWhenRevisionMoved() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "Safari", resolved: nil))
        let id = model.actions[0].id
        let key = model.beginApplicationSelection(for: id)

        model.updateFromEditor(text: "open Safari and wait 1 second", edit: nil)

        #expect(!model.resolve(
            id: id,
            application: ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari"),
            key: key
        ))
    }

    @Test func resourceSelectionRefusesWhenSnapshotMoved() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "Safari", resolved: nil))
        let id = model.actions[0].id

        let safari = ApplicationRecord(
            bundleIdentifier: "com.apple.Safari",
            displayName: "Safari",
            fileName: "Safari"
        )
        model.applyApplicationSnapshot(
            ApplicationSnapshot(revision: 1, createdAt: Date(), applications: [safari])
        )
        let key = model.beginApplicationSelection(for: id)

        model.applyApplicationSnapshot(
            ApplicationSnapshot(revision: 2, createdAt: Date(), applications: [safari])
        )

        #expect(!model.resolve(
            id: id,
            application: ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari"),
            key: key
        ))
    }

    @Test func browserSelectionRefusesWhenRevisionMoved() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open https://apple.com", edit: nil)
        let id = model.actions[0].id
        let key = model.beginResourceSelection(for: id, slot: "browser")

        model.updateFromEditor(text: "open https://apple.com and wait 1 second", edit: nil)

        #expect(!model.updateWebsiteBrowser(
            id: id,
            browser: .application(bundleIdentifier: "com.apple.Safari", label: "Safari"),
            key: key
        ))
    }

    @Test func automaticResolutionKeepsTheTypedTextAndPendingClause() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: [
                ApplicationRecord(bundleIdentifier: "com.apple.Safari", displayName: "Safari", fileName: "Safari"),
            ]
        ))
        model.updateFromEditor(text: "open safari then open", edit: nil)

        #expect(model.text == "open safari then open")
        #expect(model.hasUnresolved)
        guard case .openApplication(_, let resolved)? = model.actions.first?.draft else {
            Issue.record("Expected an open step")
            return
        }
        #expect(resolved?.identifier == "com.apple.Safari")
    }

    @Test func automaticLifecycleResolutionKeepsTheTypedText() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: [
                ApplicationRecord(bundleIdentifier: "com.apple.Safari", displayName: "Safari", fileName: "Safari"),
            ]
        ))
        model.updateFromEditor(text: "when safari opens, then open notes", edit: nil)

        #expect(model.text == "when safari opens, then open notes")
        guard case .applicationLifecycle(let reference, _, _) = model.document.trigger else {
            Issue.record("Expected a lifecycle trigger")
            return
        }
        #expect(reference?.identifier == "com.apple.Safari")
    }

    @Test func mergedOpenListPreservesTriggerAndOtherSteps() {
        let model = ComposerViewModel()
        model.updateFromEditor(
            text: "every day at 9 am, then wait 1 second, then open Research and Notes and Safari",
            edit: nil
        )
        model.applyApplicationSnapshot(ApplicationSnapshot(revision: 1, createdAt: Date(), applications: mergedCatalog))

        #expect(model.document.trigger == .daily(hour: 9, minute: 0))
        #expect(model.actions.count == 3)
        guard case .wait? = model.actions.first?.draft else {
            Issue.record("Expected the wait step to survive the grouped list")
            return
        }
        guard case .openApplication(let mergedName, let mergedReference) = model.actions[1].draft else {
            Issue.record("Expected the merged open step")
            return
        }
        #expect(mergedName == "Research and Notes")
        #expect(mergedReference?.identifier == "com.example.researchnotes")
        guard case .openApplication(let safariName, let safariReference) = model.actions[2].draft else {
            Issue.record("Expected the Safari step")
            return
        }
        #expect(safariName == "Safari")
        #expect(safariReference?.identifier == "com.apple.Safari")
    }

    @Test func mergedHideListIsResolvedWithoutTouchingOtherSteps() {
        let model = ComposerViewModel()
        model.updateFromEditor(
            text: "every day at 9 am, then wait 1 second, then hide Research and Notes and Safari",
            edit: nil
        )
        model.applyApplicationSnapshot(ApplicationSnapshot(revision: 1, createdAt: Date(), applications: mergedCatalog))

        #expect(model.document.trigger == .daily(hour: 9, minute: 0))
        #expect(model.actions.count == 3)
        guard case .wait? = model.actions.first?.draft else {
            Issue.record("Expected the wait step to survive the grouped list")
            return
        }
        guard case .hideApplication(let mergedName, let mergedReference) = model.actions[1].draft else {
            Issue.record("Expected the merged hide step")
            return
        }
        #expect(mergedName == "Research and Notes")
        #expect(mergedReference?.identifier == "com.example.researchnotes")
        guard case .hideApplication(let safariName, _) = model.actions[2].draft else {
            Issue.record("Expected the Safari step")
            return
        }
        #expect(safariName == "Safari")
    }

    @Test func markedTextBlocksPreparation() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "wait 1 second", edit: nil)
        model.setMarkedTextActive(true)

        model.prepare()

        if case .composing = model.stage {
            // expected
        } else {
            Issue.record("Marked text must block preparation")
        }
    }

    @Test func pastDueScheduleBlocksWithAReason() async {
        let model = ComposerViewModel()
        model.updateFromEditor(
            text: "once on 2020-01-01 at 09:00, then show a notification",
            edit: nil
        )

        #expect(!model.canPrepare)
        #expect(model.blockingReason?.contains("passed") == true)

        await model.save()
        #expect(model.notice?.contains("passed") == true)
    }

    @Test func pastDueScheduleIsReportedEvenWithoutSteps() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "once on 2020-01-01 at 09:00", edit: nil)

        #expect(!model.canPrepare)
        #expect(model.blockingReason?.contains("passed") == true)
    }

    @Test func editingClearsAStaleNotice() async {
        let model = ComposerViewModel()
        model.updateFromEditor(
            text: "once on 2020-01-01 at 09:00, then show a notification",
            edit: nil
        )
        await model.save()
        #expect(model.notice != nil)

        model.updateFromEditor(text: "show a notification", edit: nil)
        #expect(model.notice == nil)
    }

    @Test func acceptingWebsiteSuggestionResolvesTheStep() {
        let model = ComposerViewModel()
        model.updateFromEditor(text: "open apple.com", edit: nil)

        guard let website = model.visibleSuggestions.first(where: { $0.id.hasPrefix("website.") }) else {
            Issue.record("Expected a website suggestion")
            return
        }

        model.accept(website)
        #expect(model.text == "Open https://apple.com")
        #expect(model.canPrepare)
    }

    @Test func resolvedWorkflowCanPrepareAfterAutomaticResolution() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: [
                ApplicationRecord(bundleIdentifier: "com.apple.Notes", displayName: "Notes", fileName: "Notes"),
            ]
        ))
        model.updateFromEditor(
            text: "Open notes, then Wait 5.7 seconds, then Show a notification",
            edit: nil
        )

        #expect(model.canPrepare)
        #expect(model.blockingReason == nil)
    }

    private var mergedCatalog: [ApplicationRecord] {
        [
            ApplicationRecord(
                bundleIdentifier: "com.example.researchnotes",
                displayName: "Research and Notes",
                fileName: "Research and Notes"
            ),
            ApplicationRecord(
                bundleIdentifier: "com.apple.Safari",
                displayName: "Safari",
                fileName: "Safari"
            ),
        ]
    }
}
