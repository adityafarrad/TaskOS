import Foundation

public actor ApprovalRegistry {
    private var approvedRevisions: [AutomationID: WorkflowRevision] = [:]

    public init() {}

    public func approve(_ definition: AutomationDefinition) {
        approvedRevisions[definition.id] = definition.revision
    }

    public func isApproved(_ definition: AutomationDefinition) -> Bool {
        approvedRevisions[definition.id] == definition.revision
    }

    public func approvedRevision(for id: AutomationID) -> WorkflowRevision? {
        approvedRevisions[id]
    }

    public func revoke(_ id: AutomationID) {
        approvedRevisions[id] = nil
    }
}
