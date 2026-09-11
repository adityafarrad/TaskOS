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
        try await repository.append(makeRecord(name: "Older", startedAt: Date()))
        try await repository.append(makeRecord(name: "Newer", startedAt: Date().addingTimeInterval(1)))

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.map(\.automationName) == ["Newer", "Older"])
    }

    @Test func prunesRunsOlderThanRetentionWindow() async throws {
        let repository: any RunHistoryRepository = try makeRepository()
        let old = Date().addingTimeInterval(-RunHistoryRetention.maximumAge - 3600)
        try await repository.append(makeRecord(name: "Old", startedAt: old))
        try await repository.append(makeRecord(name: "New", startedAt: Date()))

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.map(\.automationName) == ["New"])
    }

    @Test func clearRemovesAllRuns() async throws {
        let repository: any RunHistoryRepository = try makeRepository()
        try await repository.append(makeRecord(name: "Run", startedAt: Date(timeIntervalSince1970: 1)))

        try await repository.clear()
        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.isEmpty)
    }

    @Test func updateAndInterruptedRecovery() async throws {
        let repository: any RunHistoryRepository = try makeRepository()

        let base = Date()
        let finishedID = UUID()
        var running = RunRecord(
            id: finishedID,
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Finished",
            status: .running,
            startedAt: base,
            finishedAt: base,
            actions: []
        )
        try await repository.append(running)
        running.status = .succeeded
        running.finishedAt = base.addingTimeInterval(1)
        try await repository.update(running)

        let unfinished = RunRecord(
            id: UUID(),
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Unfinished",
            status: .running,
            startedAt: base.addingTimeInterval(2),
            finishedAt: base.addingTimeInterval(2),
            actions: []
        )
        try await repository.append(unfinished)

        try await repository.markRunningAsInterrupted()

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.first { $0.automationName == "Unfinished" }?.status == .interrupted)
        #expect(runs.first { $0.automationName == "Finished" }?.status == .succeeded)
    }
}
