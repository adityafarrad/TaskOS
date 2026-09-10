import Foundation

public struct ComposerDraft: Codable, Hashable, Sendable, Identifiable {
    public let id: AutomationID
    public var name: String
    public var text: String
    public var updatedAt: Date

    public init(id: AutomationID = AutomationID(), name: String, text: String, updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.text = text
        self.updatedAt = updatedAt
    }
}

public protocol DraftRepository: Sendable {
    func loadDraft() async throws -> ComposerDraft?
    func saveDraft(_ draft: ComposerDraft) async throws
    func clearDraft() async throws
}
