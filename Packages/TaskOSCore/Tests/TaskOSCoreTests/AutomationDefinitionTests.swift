import Testing
import Foundation
import TaskOSCore

@Suite("Automation definition")
struct AutomationDefinitionTests {
    @Test func draftWithoutTriggerResolvesToManual() {
        let draft = AutomationDraft(
            name: "Morning",
            actions: [.showNotification(ShowNotificationAction(title: "Hi", message: "There"))]
        )
        #expect(draft.effectiveTrigger.id == .manual)

        let resolved = draft.resolvedDefinition()
        #expect(resolved?.trigger.id == .manual)
    }

    @Test func invalidActionPreventsResolution() {
        let draft = AutomationDraft(
            name: "Bad",
            actions: [.wait(WaitAction(duration: 99))]
        )
        #expect(draft.resolvedDefinition() == nil)
    }

    @Test func workflowAllowsAtMostTwelveActions() {
        let action = ActionConfiguration.wait(WaitAction(duration: 1))
        let tooMany = AutomationDefinition(name: "Too many", trigger: .manual(ManualTrigger()), actions: Array(repeating: action, count: 13))
        #expect(!tooMany.validate().isValid)

        let atLimit = AutomationDefinition(name: "At limit", trigger: .manual(ManualTrigger()), actions: Array(repeating: action, count: 12))
        #expect(atLimit.validate().isValid)
    }

    @Test func revisionIncrements() {
        #expect(WorkflowRevision(1).next() == WorkflowRevision(2))
        #expect(WorkflowRevision(1) < WorkflowRevision(2))
    }
}
