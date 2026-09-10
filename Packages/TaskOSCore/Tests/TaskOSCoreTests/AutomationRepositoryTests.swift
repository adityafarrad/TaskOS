import Testing
import Foundation
@testable import TaskOSCore

@Suite("File automation repository")
struct FileAutomationRepositoryTests {
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("taskos-repo-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeDefinition(name: String, id: AutomationID = AutomationID()) -> AutomationDefinition {
        AutomationDefinition(
            id: id,
            name: name,
            revision: WorkflowRevision(1),
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )
    }

    private func makeWorkflow(name: String, id: AutomationID = AutomationID(), updatedAt: Date) -> SavedWorkflow {
        SavedWorkflow(definition: makeDefinition(name: name, id: id), isEnabled: false, updatedAt: updatedAt)
    }

    @Test func savesAndLoads() async throws {
        let repository = FileAutomationRepository(directory: tempDirectory())
        let workflow = makeWorkflow(name: "Morning", updatedAt: Date(timeIntervalSince1970: 100))

        try await repository.save(workflow)
        let loaded = try await repository.loadAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Morning")
        #expect(loaded.first?.definition.actions.count == 1)
    }

    @Test func savingSameIdentityUpdatesInsteadOfDuplicating() async throws {
        let repository = FileAutomationRepository(directory: tempDirectory())
        let id = AutomationID()

        try await repository.save(makeWorkflow(name: "First", id: id, updatedAt: Date(timeIntervalSince1970: 1)))
        try await repository.save(makeWorkflow(name: "Renamed", id: id, updatedAt: Date(timeIntervalSince1970: 2)))

        let loaded = try await repository.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Renamed")
    }

    @Test func deleteRemovesWorkflow() async throws {
        let repository = FileAutomationRepository(directory: tempDirectory())
        let workflow = makeWorkflow(name: "Delete me", updatedAt: Date(timeIntervalSince1970: 1))

        try await repository.save(workflow)
        try await repository.delete(id: workflow.id)

        let loaded = try await repository.loadAll()
        #expect(loaded.isEmpty)
    }

    @Test func loadSortsNewestFirst() async throws {
        let repository = FileAutomationRepository(directory: tempDirectory())
        try await repository.save(makeWorkflow(name: "Older", updatedAt: Date(timeIntervalSince1970: 1)))
        try await repository.save(makeWorkflow(name: "Newer", updatedAt: Date(timeIntervalSince1970: 2)))

        let loaded = try await repository.loadAll()
        #expect(loaded.map(\.name) == ["Newer", "Older"])
    }

    @Test func rejectsFutureSchemaVersion() async throws {
        let directory = tempDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let workflow = makeWorkflow(name: "Future", updatedAt: Date(timeIntervalSince1970: 1))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(workflow)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["schemaVersion"] = 999
        let tampered = try JSONSerialization.data(withJSONObject: object)
        try tampered.write(to: directory.appendingPathComponent("future.json"))

        let repository = FileAutomationRepository(directory: directory)
        await #expect(throws: PersistenceError.self) {
            _ = try await repository.loadAll()
        }
    }
}
