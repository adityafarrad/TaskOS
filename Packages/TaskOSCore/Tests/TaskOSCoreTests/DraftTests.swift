import Testing
import Foundation
@testable import TaskOSCore

@Suite("Composer drafts")
struct DraftTests {
    @Test func saveLoadClearRoundTrip() async throws {
        let repository: any DraftRepository = InMemoryDraftRepository()
        let initial = try await repository.loadDraft()
        #expect(initial == nil)

        let draft = ComposerDraft(name: "Workday", text: "open Safari and wait 2 seconds")
        try await repository.saveDraft(draft)

        let loaded = try await repository.loadDraft()
        #expect(loaded == draft)

        try await repository.clearDraft()
        let cleared = try await repository.loadDraft()
        #expect(cleared == nil)
    }

    @Test func savingReplacesTheSingleDraft() async throws {
        let repository: any DraftRepository = InMemoryDraftRepository()
        try await repository.saveDraft(ComposerDraft(name: "A", text: "open Safari"))
        try await repository.saveDraft(ComposerDraft(name: "B", text: "open Notes"))

        let loaded = try await repository.loadDraft()
        #expect(loaded?.name == "B")
        #expect(loaded?.text == "open Notes")
    }
}
