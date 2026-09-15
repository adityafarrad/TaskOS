import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

@Suite("SwiftData automation repository", .serialized)
struct SwiftDataAutomationRepositoryTests {
    private func makeRepository() throws -> SwiftDataAutomationRepository {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataAutomationRepository(modelContainer: container)
    }

    private func makeWorkflow(name: String, id: AutomationID = AutomationID(), updatedAt: Date) -> SavedWorkflow {
        SavedWorkflow(
            definition: AutomationDefinition(
                id: id,
                name: name,
                revision: WorkflowRevision(1),
                trigger: .manual(ManualTrigger()),
                actions: [.wait(WaitAction(duration: 1))]
            ),
            isEnabled: false,
            updatedAt: updatedAt
        )
    }

    @Test func savesLoadsUpdatesAndDeletesThroughTheAbstraction() async throws {
        let repository: any AutomationRepository = try makeRepository()
        let id = AutomationID()

        try await repository.save(makeWorkflow(name: "First", id: id, updatedAt: Date(timeIntervalSince1970: 1)))
        try await repository.save(makeWorkflow(name: "Renamed", id: id, updatedAt: Date(timeIntervalSince1970: 2)))

        let loaded = try await repository.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Renamed")
        #expect(loaded.first?.definition.actions.count == 1)

        try await repository.delete(id: id)
        let emptied = try await repository.loadAll()
        #expect(emptied.isEmpty)
    }

    @Test func loadSortsNewestFirst() async throws {
        let repository: any AutomationRepository = try makeRepository()

        try await repository.save(makeWorkflow(name: "Older", updatedAt: Date(timeIntervalSince1970: 1)))
        try await repository.save(makeWorkflow(name: "Newer", updatedAt: Date(timeIntervalSince1970: 2)))

        let loaded = try await repository.loadAll()
        #expect(loaded.map(\.name) == ["Newer", "Older"])
    }

    @Test func oneCorruptRecordIsQuarantinedWithoutLosingValidWorkflows() async throws {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let badID = AutomationID()
        let context = ModelContext(container)
        context.insert(
            WorkflowRecord(
                id: badID.rawValue,
                name: "Bad",
                revisionValue: 1,
                isEnabled: false,
                updatedAt: Date(),
                definitionData: Data("not-json".utf8)
            )
        )
        try context.save()

        let repository = SwiftDataAutomationRepository(modelContainer: container)
        try await repository.save(makeWorkflow(name: "Good", updatedAt: Date()))

        let loaded = try await repository.loadAll()
        #expect(loaded.map(\.name) == ["Good"])
        #expect(await repository.quarantinedIdentifiers() == [badID])
    }

    @Test func deleteAllRemovesEveryWorkflow() async throws {
        let repository: any AutomationRepository = try makeRepository()
        try await repository.save(makeWorkflow(name: "A", updatedAt: Date()))
        try await repository.save(makeWorkflow(name: "B", updatedAt: Date()))

        try await repository.deleteAll()

        #expect(try await repository.loadAll().isEmpty)
    }
}
