import Testing
import Foundation
@testable import TaskOSCore

@Suite("Run history")
struct RunHistoryTests {
    private func makeRecord(name: String, startedAt: Date, status: RunStatus = .succeeded) -> RunRecord {
        RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: name,
            status: status,
            startedAt: startedAt,
            finishedAt: startedAt.addingTimeInterval(1),
            actions: [ActionRunRecord(index: 0, actionID: .wait, outcome: .succeeded, duration: 1)]
        )
    }

    @Test func recentRunsAreNewestFirst() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        try await repository.append(makeRecord(name: "Older", startedAt: Date(timeIntervalSince1970: 1)))
        try await repository.append(makeRecord(name: "Newer", startedAt: Date(timeIntervalSince1970: 2)))

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.map(\.automationName) == ["Newer", "Older"])
    }

    @Test func limitIsRespected() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        for index in 0..<5 {
            try await repository.append(makeRecord(name: "Run \(index)", startedAt: Date(timeIntervalSince1970: Double(index))))
        }

        let runs = try await repository.recentRuns(limit: 3)
        #expect(runs.count == 3)
        #expect(runs.first?.automationName == "Run 4")
    }

    @Test func clearRemovesAllRuns() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        try await repository.append(makeRecord(name: "Run", startedAt: Date(timeIntervalSince1970: 1)))

        try await repository.clear()
        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.isEmpty)
    }

    @Test func recordSurvivesSerialization() throws {
        let record = makeRecord(name: "Encoded", startedAt: Date(timeIntervalSince1970: 100), status: .failed)
        let data = try RunRecordSerialization.encode(record)
        let decoded = try RunRecordSerialization.decode(data)
        #expect(decoded == record)
    }
}
