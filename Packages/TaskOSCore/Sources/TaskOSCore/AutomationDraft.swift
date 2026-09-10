import Foundation

public struct AutomationDraft: Codable, Hashable, Sendable {
    public var name: String
    public var trigger: TriggerConfiguration?
    public var actions: [ActionConfiguration]

    public init(
        name: String = "",
        trigger: TriggerConfiguration? = nil,
        actions: [ActionConfiguration] = []
    ) {
        self.name = name
        self.trigger = trigger
        self.actions = actions
    }

    public var effectiveTrigger: TriggerConfiguration {
        trigger ?? .manual(ManualTrigger())
    }

    public func resolvedDefinition(
        id: AutomationID = AutomationID(),
        revision: WorkflowRevision = WorkflowRevision(1)
    ) -> AutomationDefinition? {
        let definition = AutomationDefinition(
            id: id,
            name: name,
            revision: revision,
            trigger: effectiveTrigger,
            actions: actions
        )
        return definition.validate().isValid ? definition : nil
    }
}
