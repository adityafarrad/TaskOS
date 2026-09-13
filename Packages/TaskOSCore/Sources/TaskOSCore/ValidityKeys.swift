import Foundation

public struct CompletionKey: Hashable, Sendable {
    public let sessionID: UUID
    public let sourceGeneration: Int
    public let cursor: SourceSpan
    public let hasMarkedText: Bool
    public let languageRevision: Int
    public let snapshotRevision: Int

    public init(
        sessionID: UUID,
        sourceGeneration: Int,
        cursor: SourceSpan,
        hasMarkedText: Bool,
        languageRevision: Int,
        snapshotRevision: Int
    ) {
        self.sessionID = sessionID
        self.sourceGeneration = sourceGeneration
        self.cursor = cursor
        self.hasMarkedText = hasMarkedText
        self.languageRevision = languageRevision
        self.snapshotRevision = snapshotRevision
    }
}

public struct ResourceSelectionKey: Hashable, Sendable {
    public let sessionID: UUID
    public let nodeID: UUID
    public let slot: String
    public let nodeRevision: WorkflowRevision
    public let snapshotRevision: Int

    public init(
        sessionID: UUID,
        nodeID: UUID,
        slot: String,
        nodeRevision: WorkflowRevision,
        snapshotRevision: Int
    ) {
        self.sessionID = sessionID
        self.nodeID = nodeID
        self.slot = slot
        self.nodeRevision = nodeRevision
        self.snapshotRevision = snapshotRevision
    }
}

public struct PreparationKey: Hashable, Sendable {
    public let sessionID: UUID
    public let authoringRevision: WorkflowRevision

    public init(sessionID: UUID, authoringRevision: WorkflowRevision) {
        self.sessionID = sessionID
        self.authoringRevision = authoringRevision
    }
}
