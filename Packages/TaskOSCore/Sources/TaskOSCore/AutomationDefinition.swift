import Foundation

public struct AutomationID: Hashable, Codable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

public struct WorkflowRevision: Hashable, Codable, Sendable, Comparable {
    public let value: Int

    public init(_ value: Int) {
        self.value = value
    }

    public static func < (lhs: WorkflowRevision, rhs: WorkflowRevision) -> Bool {
        lhs.value < rhs.value
    }

    public func next() -> WorkflowRevision {
        WorkflowRevision(value + 1)
    }
}

public struct AutomationDefinition: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1
    public static let maximumActionCount = 12

    public let schemaVersion: Int
    public let id: AutomationID
    public let name: String
    public let revision: WorkflowRevision
    public let trigger: TriggerConfiguration
    public let actions: [ActionConfiguration]

    public init(
        id: AutomationID = AutomationID(),
        name: String,
        revision: WorkflowRevision = WorkflowRevision(1),
        trigger: TriggerConfiguration,
        actions: [ActionConfiguration]
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.name = name
        self.revision = revision
        self.trigger = trigger
        self.actions = actions
    }

    public func validate() -> ValidationResult {
        validate(relativeTo: nil)
    }

    public func validate(relativeTo now: Date?) -> ValidationResult {
        var issues: [ValidationIssue] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Workflow name is required."))
        }

        issues.append(contentsOf: trigger.validate(relativeTo: now).issues)

        if actions.isEmpty {
            issues.append(.error("A workflow requires at least one action."))
        }
        if actions.count > Self.maximumActionCount {
            issues.append(.error("A workflow allows at most \(Self.maximumActionCount) actions."))
        }

        for (index, action) in actions.enumerated() {
            let prefixed = action.validate().issues.map { issue in
                ValidationIssue(severity: issue.severity, message: "Action \(index + 1): \(issue.message)")
            }
            issues.append(contentsOf: prefixed)
        }

        return ValidationResult(issues: issues)
    }
}
