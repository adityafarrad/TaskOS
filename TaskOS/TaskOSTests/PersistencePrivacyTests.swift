import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

@Suite("Persistence privacy", .serialized)
struct PersistencePrivacyTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: WorkflowRecord.self,
            RunRecordEntry.self,
            DraftRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func sourceDefinition() -> AutomationDefinition? {
        var document = ComposerDocument(
            text: "Hey TaskOS, please open Safari, so I can journal my day"
        )
        guard let id = document.actions.first?.id else { return nil }
        document.resolveApplication(
            id: id,
            reference: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )
        return document.makeDefinition(name: "Routine")
    }

    @Test func workflowRecordStoresNoSourceTextOrRationale() async throws {
        let container = try makeContainer()
        let repository = SwiftDataAutomationRepository(modelContainer: container)

        guard let definition = sourceDefinition() else {
            Issue.record("Expected a definition")
            return
        }
        try await repository.save(SavedWorkflow(definition: definition))

        let context = ModelContext(container)
        guard let record = try context.fetch(FetchDescriptor<WorkflowRecord>()).first else {
            Issue.record("Expected a stored record")
            return
        }
        let stored = (String(data: record.definitionData, encoding: .utf8) ?? "").lowercased()
        #expect(!stored.contains("hey taskos"))
        #expect(!stored.contains("journal"))
        #expect(!stored.contains("please"))
        #expect(stored.contains("com.apple.safari"))
    }

    @Test func runHistoryStoresNoSourceText() async throws {
        let container = try makeContainer()
        let repository = SwiftDataRunHistoryRepository(modelContainer: container)

        let now = Date()
        let record = RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Routine",
            status: .succeeded,
            startedAt: now,
            finishedAt: now.addingTimeInterval(1),
            actions: [
                ActionRunRecord(index: 0, actionID: .openApplication, outcome: .succeeded, duration: 0.1),
            ]
        )
        try await repository.append(record)

        let context = ModelContext(container)
        guard let entry = try context.fetch(FetchDescriptor<RunRecordEntry>()).first else {
            Issue.record("Expected a history entry")
            return
        }
        let stored = (String(data: entry.payload, encoding: .utf8) ?? "").lowercased()
        #expect(!stored.contains("hey taskos"))
        #expect(!stored.contains("journal"))
        #expect(stored.contains("openapplication"))
    }

    @Test func draftRecordIsClearedAfterSaveNewOrDiscard() async throws {
        let container = try makeContainer()
        let repository = SwiftDataDraftRepository(modelContainer: container)

        let draft = ComposerDraft(name: "Draft", text: "open Safari")
        try await repository.saveDraft(draft)
        #expect(try await repository.loadDraft() != nil)

        try await repository.clearDraft()
        #expect(try await repository.loadDraft() == nil)
    }

    @Test func structuredDraftPayloadSurvivesStoreRoundTrip() async throws {
        let container = try makeContainer()
        let repository = SwiftDataDraftRepository(modelContainer: container)

        var document = ComposerDocument(text: "show a notification")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected a notification action")
            return
        }
        document.updateAction(id: id, draft: .showNotification(title: "T", message: "kept"))
        let payload = ComposerDraft.encode(snapshot: document.makeSnapshot())

        try await repository.saveDraft(ComposerDraft(name: "Structured", text: document.text, payload: payload))
        guard let loaded = try await repository.loadDraft(),
              let snapshot = loaded.authoringSnapshot,
              let restored = ComposerDocument(snapshot: snapshot) else {
            Issue.record("Expected a structured draft")
            return
        }

        if case .showNotification(_, let message)? = restored.actions.first?.draft {
            #expect(message == "kept")
        } else {
            Issue.record("Expected a restored notification")
        }
    }

    @Test func appSourcesDoNotPrintPrivateText() throws {
        let appRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = appRoot.appendingPathComponent("TaskOS")

        let enumerator = FileManager.default.enumerator(
            at: sourcesRoot,
            includingPropertiesForKeys: nil
        )
        var inspected = 0
        while let file = enumerator?.nextObject() as? URL {
            guard file.pathExtension == "swift" else { continue }
            inspected += 1
            let contents = try String(contentsOf: file, encoding: .utf8)
            #expect(!contents.contains("print("), "\(file.lastPathComponent) must not print")
        }
        #expect(inspected > 0)
    }
}
