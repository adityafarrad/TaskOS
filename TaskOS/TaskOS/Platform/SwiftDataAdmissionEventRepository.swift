import Foundation
import SwiftData
import TaskOSCore

@Model
final class AdmissionEventRecord {
    @Attribute(.unique) var id: UUID
    var automationID: UUID
    var automationName: String
    var kind: String
    var occurredAt: Date

    init(id: UUID, automationID: UUID, automationName: String, kind: String, occurredAt: Date) {
        self.id = id
        self.automationID = automationID
        self.automationName = automationName
        self.kind = kind
        self.occurredAt = occurredAt
    }
}

@ModelActor
actor SwiftDataAdmissionEventRepository: AdmissionEventRepository {
    func record(_ event: AdmissionEvent) async {
        let entry = AdmissionEventRecord(
            id: UUID(),
            automationID: event.automationID.rawValue,
            automationName: event.automationName,
            kind: event.kind.rawValue,
            occurredAt: event.occurredAt
        )
        modelContext.insert(entry)
        try? modelContext.save()
        prune()
    }

    func recentEvents(limit: Int) async throws -> [AdmissionEvent] {
        var descriptor = FetchDescriptor<AdmissionEventRecord>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let records = try modelContext.fetch(descriptor)
        return records.compactMap { record in
            guard let kind = AdmissionEventKind(rawValue: record.kind) else { return nil }
            return AdmissionEvent(
                automationID: AutomationID(record.automationID),
                automationName: record.automationName,
                kind: kind,
                occurredAt: record.occurredAt
            )
        }
    }

    func clear() async throws {
        try modelContext.delete(model: AdmissionEventRecord.self)
        try modelContext.save()
    }

    func deleteAll(for automationID: AutomationID) async throws {
        let identifier = automationID.rawValue
        try modelContext.delete(model: AdmissionEventRecord.self, where: #Predicate { $0.automationID == identifier })
        try modelContext.save()
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-AdmissionEventRetention.maximumAge)
        if let expired = try? modelContext.fetch(
            FetchDescriptor<AdmissionEventRecord>(predicate: #Predicate { $0.occurredAt < cutoff })
        ) {
            for entry in expired {
                modelContext.delete(entry)
            }
        }

        var descriptor = FetchDescriptor<AdmissionEventRecord>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        descriptor.fetchOffset = AdmissionEventRetention.maximumEvents
        if let overflow = try? modelContext.fetch(descriptor) {
            for entry in overflow {
                modelContext.delete(entry)
            }
        }

        try? modelContext.save()
    }
}
