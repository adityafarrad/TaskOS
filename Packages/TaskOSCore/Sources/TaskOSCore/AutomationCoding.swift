import Foundation

public enum PersistenceError: Error, Equatable {
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case malformed(String)
}

public enum AutomationCoding {
    private struct SchemaProbe: Codable {
        let schemaVersion: Int
    }

    public static func encode(_ definition: AutomationDefinition) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(definition)
    }

    public static func decode(_ data: Data) throws -> AutomationDefinition {
        let decoder = JSONDecoder()

        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw PersistenceError.malformed(error.localizedDescription)
        }

        guard probe.schemaVersion <= AutomationDefinition.currentSchemaVersion else {
            throw PersistenceError.unsupportedSchemaVersion(
                found: probe.schemaVersion,
                supported: AutomationDefinition.currentSchemaVersion
            )
        }

        do {
            return try decoder.decode(AutomationDefinition.self, from: data)
        } catch {
            throw PersistenceError.malformed(error.localizedDescription)
        }
    }
}
