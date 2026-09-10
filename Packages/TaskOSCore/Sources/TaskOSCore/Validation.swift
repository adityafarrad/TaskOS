import Foundation

public struct ValidationIssue: Hashable, Sendable {
    public enum Severity: String, Sendable {
        case error
        case warning
    }

    public let severity: Severity
    public let message: String

    public init(severity: Severity, message: String) {
        self.severity = severity
        self.message = message
    }

    public static func error(_ message: String) -> ValidationIssue {
        ValidationIssue(severity: .error, message: message)
    }

    public static func warning(_ message: String) -> ValidationIssue {
        ValidationIssue(severity: .warning, message: message)
    }
}

public struct ValidationResult: Sendable {
    public let issues: [ValidationIssue]

    public init(issues: [ValidationIssue]) {
        self.issues = issues
    }

    public static let valid = ValidationResult(issues: [])

    public var isValid: Bool {
        !issues.contains { $0.severity == .error }
    }

    public var errors: [ValidationIssue] {
        issues.filter { $0.severity == .error }
    }
}

extension TriggerConfiguration {
    public func validate() -> ValidationResult {
        switch self {
        case .manual:
            return .valid
        }
    }
}

extension ActionConfiguration {
    public func validate() -> ValidationResult {
        switch self {
        case .openApplication(let action):
            return action.validate()
        case .wait(let action):
            return action.validate()
        case .showNotification(let action):
            return action.validate()
        }
    }
}

extension OpenApplicationAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if application.kind != .application {
            issues.append(.error("Open Application requires an application resource."))
        }
        if application.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Open Application requires a selected application."))
        }
        if application.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Open Application requires a display name for the selected application."))
        }
        return ValidationResult(issues: issues)
    }
}

extension WaitAction {
    public func validate() -> ValidationResult {
        if WaitAction.allowedRange.contains(duration) {
            return .valid
        }
        return ValidationResult(issues: [
            .error("Wait must be between 0.1 and 30 seconds.")
        ])
    }
}

extension ShowNotificationAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Notification requires a title."))
        }
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.warning("Notification has no message."))
        }
        return ValidationResult(issues: issues)
    }
}
