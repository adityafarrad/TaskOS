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

    private func runningRecord(id: UUID) -> RunRecord {
        RunRecord(
            id: id,
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Job",
            status: .running,
            startedAt: Date(timeIntervalSince1970: 1),
            finishedAt: Date(timeIntervalSince1970: 1),
            actions: []
        )
    }

    @Test func updateReplacesExistingRecord() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        let id = UUID()
        let running = runningRecord(id: id)
        try await repository.append(running)

        var finished = running
        finished.status = .succeeded
        finished.finishedAt = Date(timeIntervalSince1970: 2)
        try await repository.update(finished)

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.count == 1)
        #expect(runs.first?.status == .succeeded)
    }

    @Test func startupMarksUnfinishedRunsInterrupted() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        try await repository.append(runningRecord(id: UUID()))
        try await repository.append(makeRecord(name: "Done", startedAt: Date(timeIntervalSince1970: 2), status: .succeeded))

        try await repository.markRunningAsInterrupted()

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.contains { $0.status == .interrupted })
        #expect(runs.contains { $0.status == .succeeded })
    }

    @Test func deleteAllRemovesOnlyOneAutomationsRuns() async throws {
        let repository: any RunHistoryRepository = InMemoryRunHistoryRepository()
        let target = AutomationID()
        let other = AutomationID()
        let kept = RunRecord(
            automationID: other,
            revision: WorkflowRevision(1),
            automationName: "Kept",
            status: .succeeded,
            startedAt: Date(timeIntervalSince1970: 1),
            finishedAt: Date(timeIntervalSince1970: 2),
            actions: []
        )
        let removed = RunRecord(
            automationID: target,
            revision: WorkflowRevision(1),
            automationName: "Removed",
            status: .succeeded,
            startedAt: Date(timeIntervalSince1970: 3),
            finishedAt: Date(timeIntervalSince1970: 4),
            actions: []
        )
        try await repository.append(kept)
        try await repository.append(removed)

        try await repository.deleteAll(for: target)

        let runs = try await repository.recentRuns(limit: 10)
        #expect(runs.map(\.automationName) == ["Kept"])
    }

    @Test func redactionRemovesLinksAndPathsFromFailures() {
        let failure = ActionFailure(
            message: "Could not open https://example.com/callback?token=secret in Safari: file:///Users/adityasingh/secret"
        )
        let record = RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Leaky",
            status: .failed,
            startedAt: Date(timeIntervalSince1970: 1),
            finishedAt: Date(timeIntervalSince1970: 2),
            actions: [ActionRunRecord(index: 0, actionID: .openWebsite, outcome: .failed(failure), duration: 1)]
        )

        let sanitized = RunRecordRedaction.sanitize(record)
        guard case .failed(let message)? = sanitized.actions.first?.outcome else {
            Issue.record("Expected a failure outcome")
            return
        }
        #expect(!message.message.contains("token=secret"))
        #expect(!message.message.contains("/Users/adityasingh"))
        #expect(message.message.contains("[redacted]"))
    }

    @Test func redactionTruncatesVeryLongMessages() {
        let message = RunRecordRedaction.sanitize(message: String(repeating: "x", count: 5_000))
        #expect(message.count == RunRecordRedaction.maximumMessageLength + 1)
    }
}
