import Testing
import Foundation
@testable import TaskOSCore

@Suite("Approval registry")
struct ApprovalRegistryTests {
    private func definition(revision: Int, id: AutomationID = AutomationID()) -> AutomationDefinition {
        AutomationDefinition(
            id: id,
            name: "Approval test",
            revision: WorkflowRevision(revision),
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )
    }

    @Test func approvalIsBoundToExactRevision() async {
        let registry = ApprovalRegistry()
        let approved = definition(revision: 1)

        await registry.approve(approved)
        #expect(await registry.isApproved(approved))

        let bumped = AutomationDefinition(
            id: approved.id,
            name: approved.name,
            revision: WorkflowRevision(2),
            trigger: approved.trigger,
            actions: approved.actions
        )
        #expect(await !registry.isApproved(bumped))
    }

    @Test func revokeRemovesApproval() async {
        let registry = ApprovalRegistry()
        let approved = definition(revision: 1)

        await registry.approve(approved)
        await registry.revoke(approved.id)
        #expect(await !registry.isApproved(approved))
    }
}
