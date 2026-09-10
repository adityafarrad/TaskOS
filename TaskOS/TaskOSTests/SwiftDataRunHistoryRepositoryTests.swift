import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

@Suite("SwiftData run history repository", .serialized)
struct SwiftDataRunHistoryRepositoryTests {
    private func makeRepository() throws -> SwiftDataRunHistoryRepository {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            RunRecordEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataRunHistoryRepository(modelContainer: container)
    }

    private func makeRecord(name: String, startedAt: Date) -> RunRecord {
        RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: name,
            status: .succeeded,
            startedAt: startedAt,
            finishedAt: startedAt.addingTimeInterval(1),
            actions: [ActionRunRecord(index: 0, actionID: .wait, outcome: .succeeded, duration: 1)]
        )
    }

    @Test func appendsAndReadsNewestFirst() async throws {
        let repository: any RunHistoryRepository = try makeRepository()
        try await repository.append(makeRecord(name: "Older", startedAt: Date(timeIntervalSince1970: 1)))
        try await repository.append(makeRecord(name: "Newer", startedAt: Date(timeIntervalSince1970: 2)))

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.map(\.automationName) == ["Newer", "Older"])
    }

    @Test func clearRemovesAllRuns() async throws {
        let repository: any RunHistoryRepository = try makeRepository()
        try await repository.append(makeRecord(name: "Run", startedAt: Date(timeIntervalSince1970: 1)))

        try await repository.clear()
        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.isEmpty)
    }
}
