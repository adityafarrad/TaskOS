import Foundation

public enum CommandLimits {
    public static let maximumCharacters = 2_000
    public static let maximumUTF16Units = 16_384
    public static let maximumTokens = 128
    public static let maximumActions = 12
    public static let maximumVisibleSuggestions = 8
    public static let maximumApplications = 5_000
}

public struct CommandInput: Hashable, Sendable {
    public enum GrammarLocale: String, Hashable, Sendable {
        case english = "en"
    }

    public let text: String
    public let selection: SourceSpan
    public let hasMarkedText: Bool
    public let sourceGeneration: Int
    public let locale: GrammarLocale

    public init(
        text: String,
        selection: SourceSpan? = nil,
        hasMarkedText: Bool = false,
        sourceGeneration: Int = 0,
        locale: GrammarLocale = .english
    ) {
        self.text = text
        let utf16Count = text.utf16.count
        let requested = selection ?? SourceSpan(start: utf16Count, end: utf16Count)
        self.selection = requested.isValid(in: text)
            ? requested
            : SourceSpan(start: utf16Count, end: utf16Count)
        self.hasMarkedText = hasMarkedText
        self.sourceGeneration = sourceGeneration
        self.locale = locale
    }

    public var isOverCharacterLimit: Bool {
        text.count > CommandLimits.maximumCharacters
    }

    public var isOverUTF16Limit: Bool {
        text.utf16.count > CommandLimits.maximumUTF16Units
    }

    public var isOverLimit: Bool {
        isOverCharacterLimit || isOverUTF16Limit
    }
}

public struct CommandEdit: Hashable, Sendable {
    public let range: SourceSpan
    public let replacement: String
    public let resultingSelection: SourceSpan?

    public init(range: SourceSpan, replacement: String, resultingSelection: SourceSpan? = nil) {
        self.range = range
        self.replacement = replacement
        self.resultingSelection = resultingSelection
    }

    public func isValid(in text: String) -> Bool {
        range.isValid(in: text)
    }

    public func applied(to text: String) -> String? {
        guard let range = range.range(in: text) else {
            return nil
        }
        return text.replacingCharacters(in: range, with: replacement)
    }

    public func selection(in text: String) -> SourceSpan? {
        guard let applied = applied(to: text) else {
            return nil
        }
        if let resultingSelection, resultingSelection.isValid(in: applied) {
            return resultingSelection
        }
        let start = range.start
        return SourceSpan(start: start, end: start + replacement.utf16.count)
    }
}

public struct CommandLiteral: Hashable, Sendable {
    public let value: String
    public let span: SourceSpan

    public init(value: String, span: SourceSpan) {
        self.value = value
        self.span = span
    }
}

public enum CommandLiteralError: Error, Hashable, Sendable {
    case notQuoted
    case unclosedQuote
}

public enum CommandLiteralScanner {
    public static func scan(_ text: String, at start: Int) -> Result<CommandLiteral, CommandLiteralError> {
        guard start >= 0, start < text.utf16.count,
              let openRange = SourceSpan(start: start, end: start + 1).range(in: text),
              text[openRange] == "\"" else {
            return .failure(.notQuoted)
        }

        var value = ""
        var offset = start + 1
        var index = text.index(after: openRange.lowerBound)

        while index < text.endIndex {
            let character = text[index]

            if character == "\\" {
                let next = text.index(after: index)
                guard next < text.endIndex else {
                    return .failure(.unclosedQuote)
                }
                let escaped = text[next]
                if escaped == "\"" {
                    value.append("\"")
                } else if escaped == "\\" {
                    value.append("\\")
                } else {
                    value.append("\\")
                    value.append(escaped)
                }
                offset += 1 + String(escaped).utf16.count
                index = text.index(after: next)
                continue
            }

            if character == "\"" {
                offset += 1
                return .success(CommandLiteral(value: value, span: SourceSpan(start: start, end: offset)))
            }

            value.append(character)
            offset += String(character).utf16.count
            index = text.index(after: index)
        }

        return .failure(.unclosedQuote)
    }
}

public enum CapabilityReference: Hashable, Sendable {
    case action(ActionID)
    case trigger(TriggerID)

    public var stableID: String {
        switch self {
        case .action(let id): return "action.\(id.stableID)"
        case .trigger(let id): return "trigger.\(id.stableID)"
        }
    }
}

public struct InterpretationEvidence: Hashable, Sendable {
    public let capability: CapabilityReference
    public let span: SourceSpan
    public let ruleID: String

    public init(capability: CapabilityReference, span: SourceSpan, ruleID: String) {
        self.capability = capability
        self.span = span
        self.ruleID = ruleID
    }
}

public enum ExpectedSlot: String, Hashable, Sendable, CaseIterable {
    case application
    case file
    case url
    case preset
    case duration
    case text
    case scheduleTime
    case triggerEvent
}

public struct TextReplacement: Hashable, Sendable {
    public let span: SourceSpan
    public let replacement: String

    public init(span: SourceSpan, replacement: String) {
        self.span = span
        self.replacement = replacement
    }
}

public struct ParseClarification: Hashable, Sendable {
    public let span: SourceSpan
    public let question: String
    public let replacements: [TextReplacement]

    public init(span: SourceSpan, question: String, replacements: [TextReplacement] = []) {
        self.span = span
        self.question = question
        self.replacements = replacements
    }
}

public struct SourceCoverage: Hashable, Sendable {
    public let coveredSpans: [SourceSpan]
    public let unresolvedSpans: [SourceSpan]

    public init(coveredSpans: [SourceSpan], unresolvedSpans: [SourceSpan]) {
        self.coveredSpans = coveredSpans
        self.unresolvedSpans = unresolvedSpans
    }

    public var isComplete: Bool {
        unresolvedSpans.isEmpty
    }

    public static let empty = SourceCoverage(coveredSpans: [], unresolvedSpans: [])
}
