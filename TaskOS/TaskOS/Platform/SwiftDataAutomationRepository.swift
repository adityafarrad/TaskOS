import Foundation
import SwiftData
import TaskOSCore

@Model
final class WorkflowRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var revisionValue: Int
    var isEnabled: Bool
    var updatedAt: Date
    var definitionData: Data

    init(
        id: UUID,
        name: String,
        revisionValue: Int,
        isEnabled: Bool,
        updatedAt: Date,
        definitionData: Data
    ) {
        self.id = id
        self.name = name
        self.revisionValue = revisionValue
        self.isEnabled = isEnabled
        self.updatedAt = updatedAt
        self.definitionData = definitionData
    }
}

@ModelActor
actor SwiftDataAutomationRepository: AutomationRepository {
    func loadAll() async throws -> [SavedWorkflow] {
        let descriptor = FetchDescriptor<WorkflowRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return try records.map { try SavedWorkflowSerialization.decode($0.definitionData) }
    }

    func save(_ workflow: SavedWorkflow) async throws {
        let data = try SavedWorkflowSerialization.encode(workflow)
        let identifier = workflow.id.rawValue
        let descriptor = FetchDescriptor<WorkflowRecord>(
            predicate: #Predicate { $0.id == identifier }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = workflow.name
            existing.revisionValue = workflow.definition.revision.value
            existing.isEnabled = workflow.isEnabled
            existing.updatedAt = workflow.updatedAt
            existing.definitionData = data
        } else {
            let record = WorkflowRecord(
                id: identifier,
                name: workflow.name,
                revisionValue: workflow.definition.revision.value,
                isEnabled: workflow.isEnabled,
                updatedAt: workflow.updatedAt,
                definitionData: data
            )
            modelContext.insert(record)
        }

        try modelContext.save()
    }

    func delete(id: AutomationID) async throws {
        let identifier = id.rawValue
        let descriptor = FetchDescriptor<WorkflowRecord>(
            predicate: #Predicate { $0.id == identifier }
        )
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
