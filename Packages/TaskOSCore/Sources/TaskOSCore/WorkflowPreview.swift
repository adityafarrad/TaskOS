import Foundation

public enum PreviewActionStatus: String, Codable, Sendable, Hashable {
    case ready
    case needsPermission
    case missingResource
}

public struct ActionPreview: Hashable, Sendable {
    public let index: Int
    public let actionID: ActionID
    public let title: String
    public let targetLabel: String?
    public let status: PreviewActionStatus
    public let detail: String?

    public init(
        index: Int,
        actionID: ActionID,
        title: String,
        targetLabel: String?,
        status: PreviewActionStatus,
        detail: String?
    ) {
        self.index = index
        self.actionID = actionID
        self.title = title
        self.targetLabel = targetLabel
        self.status = status
        self.detail = detail
    }
}

public struct WorkflowPreview: Sendable, Equatable {
    public let automationID: AutomationID
    public let revision: WorkflowRevision
    public let name: String
    public let triggerTitle: String
    public let actions: [ActionPreview]
    public let requiredPermissions: Set<PermissionKind>
    public let issues: [ValidationIssue]
    public let willRunAutomatically: Bool

    public init(
        automationID: AutomationID,
        revision: WorkflowRevision,
        name: String,
        triggerTitle: String,
        actions: [ActionPreview],
        requiredPermissions: Set<PermissionKind>,
        issues: [ValidationIssue],
        willRunAutomatically: Bool
    ) {
        self.automationID = automationID
        self.revision = revision
        self.name = name
        self.triggerTitle = triggerTitle
        self.actions = actions
        self.requiredPermissions = requiredPermissions
        self.issues = issues
        self.willRunAutomatically = willRunAutomatically
    }

    public var isValid: Bool {
        !issues.contains { $0.severity == .error }
    }

    public var isRunnable: Bool {
        isValid && !actions.contains { $0.status == .missingResource }
    }
}
