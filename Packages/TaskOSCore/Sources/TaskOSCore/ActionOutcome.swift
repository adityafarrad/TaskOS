import Foundation

public struct ActionFailure: Codable, Sendable, Equatable {
    public let message: String
    public let isTimedOut: Bool

    public init(message: String, isTimedOut: Bool = false) {
        self.message = message
        self.isTimedOut = isTimedOut
    }
}

public enum ActionOutcome: Codable, Sendable, Equatable {
    case succeeded
    case failed(ActionFailure)
    case cancelled
    case notExecuted

    public var isSuccess: Bool {
        self == .succeeded
    }
}

public enum RunStatus: String, Codable, Sendable, Equatable {
    case succeeded
    case failed
    case timedOut
    case cancelled
}

public struct ActionRunRecord: Codable, Sendable, Equatable {
    public let index: Int
    public let actionID: ActionID
    public let outcome: ActionOutcome
    public let duration: TimeInterval

    public init(index: Int, actionID: ActionID, outcome: ActionOutcome, duration: TimeInterval) {
        self.index = index
        self.actionID = actionID
        self.outcome = outcome
        self.duration = duration
    }
}

public struct RunRecord: Codable, Sendable, Equatable {
    public let automationID: AutomationID
    public let revision: WorkflowRevision
    public let automationName: String
    public let status: RunStatus
    public let startedAt: Date
    public let finishedAt: Date
    public let actions: [ActionRunRecord]

    public init(
        automationID: AutomationID,
        revision: WorkflowRevision,
        automationName: String,
        status: RunStatus,
        startedAt: Date,
        finishedAt: Date,
        actions: [ActionRunRecord]
    ) {
        self.automationID = automationID
        self.revision = revision
        self.automationName = automationName
        self.status = status
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.actions = actions
    }

    public var duration: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }
}
