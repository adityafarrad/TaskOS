import Foundation

public struct ComposerDraft: Codable, Hashable, Sendable, Identifiable {
    public let id: AutomationID
    public var name: String
    public var text: String
    public var updatedAt: Date
    public var payload: Data?
    public var recoveryError: String?

    public init(
        id: AutomationID = AutomationID(),
        name: String,
        text: String,
        updatedAt: Date = Date(),
        payload: Data? = nil,
        recoveryError: String? = nil
    ) {
        self.id = id
        self.name = name
        self.text = text
        self.updatedAt = updatedAt
        self.payload = payload
        self.recoveryError = recoveryError
    }

    public var schemaVersion: Int {
        payload == nil ? 1 : AuthoringSnapshot.currentVersion
    }

    public var authoringSnapshot: AuthoringSnapshot? {
        guard let payload else { return nil }
        return try? JSONDecoder().decode(AuthoringSnapshot.self, from: payload)
    }

    public static func encode(snapshot: AuthoringSnapshot) -> Data? {
        try? JSONEncoder().encode(snapshot)
    }
}

public protocol DraftRepository: Sendable {
    func loadDraft() async throws -> ComposerDraft?
    func saveDraft(_ draft: ComposerDraft) async throws
    func clearDraft() async throws
}
