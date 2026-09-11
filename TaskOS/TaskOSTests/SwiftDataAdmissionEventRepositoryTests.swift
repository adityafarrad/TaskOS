import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

@Suite("SwiftData admission event repository", .serialized)
struct SwiftDataAdmissionEventRepositoryTests {
    private func makeRepository() throws -> SwiftDataAdmissionEventRepository {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            RunRecordEntry.self,
            AdmissionEventRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataAdmissionEventRepository(modelContainer: container)
    }

    private func event(_ name: String, kind: AdmissionEventKind, at date: Date) -> AdmissionEvent {
        AdmissionEvent(automationID: AutomationID(), automationName: name, kind: kind, occurredAt: date)
    }

    @Test func recordsAndReadsNewestFirst() async throws {
        let repository = try makeRepository()
        let base = Date()
        await repository.record(event("Older", kind: .expired, at: base))
        await repository.record(event("Newer", kind: .queueOverflow, at: base.addingTimeInterval(1)))

        let events = try await repository.recentEvents(limit: 10)
        #expect(events.map(\.automationName) == ["Newer", "Older"])
        #expect(events.first?.kind == .queueOverflow)
    }

    @Test func clearRemovesAll() async throws {
        let repository = try makeRepository()
        await repository.record(event("One", kind: .cooldownSuppressed, at: Date()))
        try await repository.clear()
        #expect(try await repository.recentEvents(limit: 10).isEmpty)
    }
}
