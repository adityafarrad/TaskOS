import Foundation
import SwiftData
import TaskOSCore

@Model
final class RunRecordEntry {
    @Attribute(.unique) var id: UUID
    var automationID: UUID
    var automationName: String
    var status: String
    var startedAt: Date
    var actionCount: Int
    var payload: Data

    init(
        id: UUID,
        automationID: UUID,
        automationName: String,
        status: String,
        startedAt: Date,
        actionCount: Int,
        payload: Data
    ) {
        self.id = id
        self.automationID = automationID
        self.automationName = automationName
        self.status = status
        self.startedAt = startedAt
        self.actionCount = actionCount
        self.payload = payload
    }
}

@ModelActor
actor SwiftDataRunHistoryRepository: RunHistoryRepository {
    private static let retentionLimit = 200

    func recentRuns(limit: Int) async throws -> [RunRecord] {
        var descriptor = FetchDescriptor<RunRecordEntry>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let entries = try modelContext.fetch(descriptor)
        return try entries.map { try RunRecordSerialization.decode($0.payload) }
    }

    func append(_ record: RunRecord) async throws {
        let entry = RunRecordEntry(
            id: record.id,
            automationID: record.automationID.rawValue,
            automationName: record.automationName,
            status: record.status.rawValue,
            startedAt: record.startedAt,
            actionCount: record.actions.count,
            payload: try RunRecordSerialization.encode(record)
        )
        modelContext.insert(entry)
        try modelContext.save()
        try prune()
    }

    func update(_ record: RunRecord) async throws {
        let identifier = record.id
        let descriptor = FetchDescriptor<RunRecordEntry>(predicate: #Predicate { $0.id == identifier })
        if let entry = try modelContext.fetch(descriptor).first {
            entry.status = record.status.rawValue
            entry.startedAt = record.startedAt
            entry.actionCount = record.actions.count
            entry.payload = try RunRecordSerialization.encode(record)
            try modelContext.save()
        } else {
            try await append(record)
        }
    }

    func markRunningAsInterrupted() async throws {
        let running = RunStatus.running.rawValue
        let descriptor = FetchDescriptor<RunRecordEntry>(predicate: #Predicate { $0.status == running })
        let entries = try modelContext.fetch(descriptor)
        guard !entries.isEmpty else { return }

        for entry in entries {
            var record = try RunRecordSerialization.decode(entry.payload)
            record.status = .interrupted
            entry.status = RunStatus.interrupted.rawValue
            entry.payload = try RunRecordSerialization.encode(record)
        }
        try modelContext.save()
    }

    func clear() async throws {
        try modelContext.delete(model: RunRecordEntry.self)
        try modelContext.save()
    }

    private func prune() throws {
        var descriptor = FetchDescriptor<RunRecordEntry>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchOffset = Self.retentionLimit
        let overflow = try modelContext.fetch(descriptor)
        guard !overflow.isEmpty else { return }
        for entry in overflow {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }
}
