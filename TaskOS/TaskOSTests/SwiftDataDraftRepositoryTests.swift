import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

@Suite("SwiftData draft repository", .serialized)
struct SwiftDataDraftRepositoryTests {
    private func makeRepository() throws -> SwiftDataDraftRepository {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            RunRecordEntry.self,
            DraftRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataDraftRepository(modelContainer: container)
    }

    @Test func saveLoadClearRoundTrip() async throws {
        let repository: any DraftRepository = try makeRepository()
        let empty = try await repository.loadDraft()
        #expect(empty == nil)

        let draft = ComposerDraft(name: "Workday", text: "open Safari and wait 2 seconds")
        try await repository.saveDraft(draft)
        let loaded = try await repository.loadDraft()
        #expect(loaded == draft)

        try await repository.clearDraft()
        let cleared = try await repository.loadDraft()
        #expect(cleared == nil)
    }

    @Test func savingReplacesTheSingleDraft() async throws {
        let repository: any DraftRepository = try makeRepository()
        try await repository.saveDraft(ComposerDraft(name: "A", text: "open Safari"))
        try await repository.saveDraft(ComposerDraft(name: "B", text: "open Notes"))

        let loaded = try await repository.loadDraft()
        #expect(loaded?.name == "B")
    }
}
