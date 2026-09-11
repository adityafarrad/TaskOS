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
        validate(relativeTo: nil)
    }

    public func validate(relativeTo now: Date?) -> ValidationResult {
        switch self {
        case .manual:
            return .valid
        case .schedule(let schedule):
            return schedule.validate(relativeTo: now)
        }
    }
}

extension ActionConfiguration {
    public func validate() -> ValidationResult {
        switch self {
        case .openApplication(let action):
            return action.validate()
        case .hideApplication(let action):
            return action.validate()
        case .quitApplication(let action):
            return action.validate()
        case .openFile(let action):
            return action.validate()
        case .revealInFinder(let action):
            return action.validate()
        case .openWebsite(let action):
            return action.validate()
        case .arrangeWindow(let action):
            return action.validate()
        case .wait(let action):
            return action.validate()
        case .showNotification(let action):
            return action.validate()
        case .copyText(let action):
            return action.validate()
        }
    }
}

extension ArrangeWindowAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if application.kind != .application {
            issues.append(.error("Arrange Window requires an application resource."))
        }
        if application.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Arrange Window requires a selected application."))
        }
        if application.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Arrange Window requires a display name for the selected application."))
        }
        return ValidationResult(issues: issues)
    }
}

extension HideApplicationAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if application.kind != .application {
            issues.append(.error("Hide Application requires an application resource."))
        }
        if application.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Hide Application requires a selected application."))
        }
        if application.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Hide Application requires a display name for the selected application."))
        }
        return ValidationResult(issues: issues)
    }
}

extension QuitApplicationAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if application.kind != .application {
            issues.append(.error("Quit Application requires an application resource."))
        }
        if application.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Quit Application requires a selected application."))
        }
        if application.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Quit Application requires a display name for the selected application."))
        }
        if Self.protectedBundleIdentifiers.contains(application.identifier) {
            issues.append(.error("TaskOS cannot quit itself, Finder, or system infrastructure."))
        }
        return ValidationResult(issues: issues)
    }
}

extension OpenFileAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []
        if target.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || target.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.error("Open File requires an explicitly selected file or folder."))
        }
        if target.isExecutableOrUnsupported {
            issues.append(.error("TaskOS cannot open applications, installers, scripts, or automation files."))
        }
        return ValidationResult(issues: issues)
    }
}

extension RevealInFinderAction {
    public func validate() -> ValidationResult {
        if target.path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || target.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(issues: [.error("Reveal in Finder requires an explicitly selected item.")])
        }
        return .valid
    }
}

extension OpenWebsiteAction {
    public func validate() -> ValidationResult {
        var issues: [ValidationIssue] = []

        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            issues.append(.error("Open Website requires a web address."))
        } else if !Self.isAbsoluteHTTPURL(trimmed) {
            issues.append(.error("Web address must be an absolute http or https URL."))
        }

        if let browser, browser.kind != .application {
            issues.append(.error("Open Website browser must be an application."))
        }

        return ValidationResult(issues: issues)
    }

    public static func isAbsoluteHTTPURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value) else { return false }
        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }
        guard let host = components.host, !host.isEmpty else { return false }
        return true
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

extension CopyTextAction {
    public func validate() -> ValidationResult {
        if text.isEmpty {
            return ValidationResult(issues: [.error("Copy Text requires literal text.")])
        }
        if text.count > Self.maximumLength {
            return ValidationResult(issues: [.error("Copied text must be at most \(Self.maximumLength) characters.")])
        }
        return .valid
    }
}
