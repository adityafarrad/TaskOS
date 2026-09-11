import Foundation

public enum ParsedClauseKind: Hashable, Sendable {
    case schedule
    case openApplication
    case hideApplication
    case quitApplication
    case openFile
    case revealInFinder
    case applicationLifecycle
    case wake
    case displayConnection
    case externalVolume
    case arrangeWindow
    case wait
    case showNotification
    case copyText
    case unsupported
    case unrecognized
}

public enum ParsedSchedule: Hashable, Sendable {
    case daily(hour: Int, minute: Int)
    case weekdays(Set<Weekday>, hour: Int, minute: Int)
    case interval(TimeInterval)
    case relative(TimeInterval)
    case once(hour: Int, minute: Int)
    case incomplete
}

public enum ParsedParameter: Hashable, Sendable {
    case resourceNames([String])
    case duration(TimeInterval)
    case arrange(preset: WindowPreset?, applicationName: String)
    case schedule(ParsedSchedule)
    case copyText(String)
    case fileSelection(kind: FileTarget.Kind)
    case lifecycle(event: LifecycleEvent?, applicationName: String)
    case wake
    case display(DisplayEvent)
    case volume(VolumeEvent)
    case none
}

public struct ParsedClause: Hashable, Sendable {
    public let kind: ParsedClauseKind
    public let span: SourceSpan
    public let parameter: ParsedParameter
    public let detail: String?

    public init(kind: ParsedClauseKind, span: SourceSpan, parameter: ParsedParameter, detail: String?) {
        self.kind = kind
        self.span = span
        self.parameter = parameter
        self.detail = detail
    }

    public var resourceNames: [String] {
        if case .resourceNames(let names) = parameter {
            return names
        }
        return []
    }

    public var duration: TimeInterval? {
        if case .duration(let value) = parameter {
            return value
        }
        return nil
    }

    public var arrangePreset: WindowPreset? {
        if case .arrange(let preset, _) = parameter {
            return preset
        }
        return nil
    }

    public var arrangeApplicationName: String? {
        if case .arrange(_, let name) = parameter {
            return name
        }
        return nil
    }

    public var schedule: ParsedSchedule? {
        if case .schedule(let value) = parameter {
            return value
        }
        return nil
    }

    public var copyText: String? {
        if case .copyText(let value) = parameter {
            return value
        }
        return nil
    }

    public var fileSelectionKind: FileTarget.Kind? {
        if case .fileSelection(let kind) = parameter {
            return kind
        }
        return nil
    }

    public var lifecycleEvent: LifecycleEvent? {
        if case .lifecycle(let event, _) = parameter {
            return event
        }
        return nil
    }

    public var lifecycleApplicationName: String? {
        if case .lifecycle(_, let name) = parameter {
            return name
        }
        return nil
    }

    public var displayEvent: DisplayEvent? {
        if case .display(let event) = parameter {
            return event
        }
        return nil
    }

    public var volumeEvent: VolumeEvent? {
        if case .volume(let event) = parameter {
            return event
        }
        return nil
    }
}

public enum ParseOutcome: String, Hashable, Sendable, Codable {
    case complete
    case needsInput
    case unrecognized
    case unsupported
}

public struct ParseDiagnostic: Hashable, Sendable {
    public let severity: ValidationIssue.Severity
    public let message: String
    public let span: SourceSpan?

    public init(severity: ValidationIssue.Severity, message: String, span: SourceSpan?) {
        self.severity = severity
        self.message = message
        self.span = span
    }

    public static func error(_ message: String, span: SourceSpan?) -> ParseDiagnostic {
        ParseDiagnostic(severity: .error, message: message, span: span)
    }

    public static func warning(_ message: String, span: SourceSpan?) -> ParseDiagnostic {
        ParseDiagnostic(severity: .warning, message: message, span: span)
    }
}

public struct ParsedCommand: Hashable, Sendable {
    public let text: String
    public let clauses: [ParsedClause]
    public let diagnostics: [ParseDiagnostic]
    public let outcome: ParseOutcome

    public init(text: String, clauses: [ParsedClause], diagnostics: [ParseDiagnostic], outcome: ParseOutcome) {
        self.text = text
        self.clauses = clauses
        self.diagnostics = diagnostics
        self.outcome = outcome
    }

    public var isComplete: Bool {
        outcome == .complete
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }

    public var recognizedActionClauses: [ParsedClause] {
        clauses.filter { clause in
            switch clause.kind {
            case .openApplication, .hideApplication, .quitApplication,
                 .openFile, .revealInFinder, .arrangeWindow, .wait,
                 .showNotification, .copyText:
                return true
            case .schedule, .applicationLifecycle, .wake, .displayConnection,
                 .externalVolume, .unsupported, .unrecognized:
                return false
            }
        }
    }
}
