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
    case powerSource
    case batteryThreshold
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
    case absolute(year: Int, month: Int, day: Int, hour: Int, minute: Int)
    case timeOfDay(hour: Int, minute: Int)
    case dayQualifier
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
    case power(PowerEvent)
    case battery(comparator: ThresholdComparison, percentage: Int)
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

    public var powerEvent: PowerEvent? {
        if case .power(let event) = parameter {
            return event
        }
        return nil
    }

    public var batteryThreshold: (comparator: ThresholdComparison, percentage: Int)? {
        if case .battery(let comparator, let percentage) = parameter {
            return (comparator, percentage)
        }
        return nil
    }

    public var capability: CapabilityReference? {
        switch kind {
        case .openApplication: return .action(.openApplication)
        case .hideApplication: return .action(.hideApplication)
        case .quitApplication: return .action(.quitApplication)
        case .openFile: return .action(.openFile)
        case .revealInFinder: return .action(.revealInFinder)
        case .arrangeWindow: return .action(.arrangeWindow)
        case .wait: return .action(.wait)
        case .showNotification: return .action(.showNotification)
        case .copyText: return .action(.copyText)
        case .schedule: return .trigger(.schedule)
        case .applicationLifecycle: return .trigger(.applicationLifecycle)
        case .wake: return .trigger(.wake)
        case .displayConnection: return .trigger(.displayConnection)
        case .externalVolume: return .trigger(.externalVolume)
        case .powerSource: return .trigger(.powerSource)
        case .batteryThreshold: return .trigger(.batteryThreshold)
        case .unsupported, .unrecognized: return nil
        }
    }

    public var evidence: InterpretationEvidence? {
        guard let capability else { return nil }
        return InterpretationEvidence(capability: capability, span: span, ruleID: capability.stableID)
    }

    public var expectedSlots: [ExpectedSlot] {
        switch kind {
        case .openApplication, .hideApplication, .quitApplication:
            return resourceNames.isEmpty ? [.application] : []
        case .openFile, .revealInFinder:
            return fileSelectionKind == nil ? [.file] : []
        case .arrangeWindow:
            var slots: [ExpectedSlot] = []
            if (arrangeApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                slots.append(.application)
            }
            if arrangePreset == nil {
                slots.append(.preset)
            }
            return slots
        case .wait:
            guard let duration else { return [.duration] }
            return WaitAction.allowedRange.contains(duration) ? [] : [.duration]
        case .copyText:
            return (copyText ?? "").isEmpty ? [.text] : []
        case .schedule:
            return schedule == .incomplete ? [.scheduleTime] : []
        case .applicationLifecycle:
            var slots: [ExpectedSlot] = []
            if (lifecycleApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                slots.append(.application)
            }
            if lifecycleEvent == nil {
                slots.append(.triggerEvent)
            }
            return slots
        case .wake, .displayConnection, .externalVolume, .powerSource, .batteryThreshold,
             .showNotification, .unsupported, .unrecognized:
            return []
        }
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
    public let coverage: SourceCoverage
    public let clarifications: [ParseClarification]

    public init(
        text: String,
        clauses: [ParsedClause],
        diagnostics: [ParseDiagnostic],
        outcome: ParseOutcome,
        coverage: SourceCoverage = .empty,
        clarifications: [ParseClarification] = []
    ) {
        self.text = text
        self.clauses = clauses
        self.diagnostics = diagnostics
        self.outcome = outcome
        self.coverage = coverage
        self.clarifications = clarifications
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
                 .externalVolume, .powerSource, .batteryThreshold,
                 .unsupported, .unrecognized:
                return false
            }
        }
    }
}
