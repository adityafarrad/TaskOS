import Foundation

public protocol RunHistoryRepository: Sendable {
    func recentRuns(limit: Int) async throws -> [RunRecord]
    func append(_ record: RunRecord) async throws
    func clear() async throws
}

public enum RunRecordSerialization {
    public static func encode(_ record: RunRecord) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(record)
    }

    public static func decode(_ data: Data) throws -> RunRecord {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(RunRecord.self, from: data)
        } catch {
            throw PersistenceError.malformed(error.localizedDescription)
        }
    }
}
