import Foundation

public struct SavedWorkflow: Hashable, Sendable, Codable, Identifiable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let definition: AutomationDefinition
    public var isEnabled: Bool
    public var updatedAt: Date

    public var id: AutomationID {
        definition.id
    }

    public var name: String {
        definition.name
    }

    public init(definition: AutomationDefinition, isEnabled: Bool = false, updatedAt: Date = Date()) {
        self.schemaVersion = Self.currentSchemaVersion
        self.definition = definition
        self.isEnabled = isEnabled
        self.updatedAt = updatedAt
    }
}

public protocol AutomationRepository: Sendable {
    func loadAll() async throws -> [SavedWorkflow]
    func save(_ workflow: SavedWorkflow) async throws
    func delete(id: AutomationID) async throws
}

public enum SavedWorkflowSerialization {
    public static func encode(_ workflow: SavedWorkflow) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(workflow)
    }

    public static func decode(_ data: Data) throws -> SavedWorkflow {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct SchemaProbe: Codable {
            let schemaVersion: Int
        }

        do {
            let probe = try decoder.decode(SchemaProbe.self, from: data)
            guard probe.schemaVersion <= SavedWorkflow.currentSchemaVersion else {
                throw PersistenceError.unsupportedSchemaVersion(
                    found: probe.schemaVersion,
                    supported: SavedWorkflow.currentSchemaVersion
                )
            }
            return try decoder.decode(SavedWorkflow.self, from: data)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.malformed(error.localizedDescription)
        }
    }
}
