import Foundation
import SwiftData
import TaskOSCore

@Model
final class DraftRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var text: String
    var updatedAt: Date

    init(id: UUID, name: String, text: String, updatedAt: Date) {
        self.id = id
        self.name = name
        self.text = text
        self.updatedAt = updatedAt
    }
}

@ModelActor
actor SwiftDataDraftRepository: DraftRepository {
    func loadDraft() async throws -> ComposerDraft? {
        var descriptor = FetchDescriptor<DraftRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return ComposerDraft(
            id: AutomationID(record.id),
            name: record.name,
            text: record.text,
            updatedAt: record.updatedAt
        )
    }

    func saveDraft(_ draft: ComposerDraft) async throws {
        try modelContext.delete(model: DraftRecord.self)
        modelContext.insert(
            DraftRecord(
                id: draft.id.rawValue,
                name: draft.name,
                text: draft.text,
                updatedAt: draft.updatedAt
            )
        )
        try modelContext.save()
    }

    func clearDraft() async throws {
        try modelContext.delete(model: DraftRecord.self)
        try modelContext.save()
    }
}
