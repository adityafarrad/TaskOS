import Foundation

struct CommandToken: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case word(String)
        case number(Double)
        case punctuation(String)
    }

    let kind: Kind
    let span: SourceSpan
    let original: String
}

enum CommandTokenizer {
    static func tokenize(_ input: String) -> [CommandToken] {
        var tokens: [CommandToken] = []
        let characters = Array(input)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character.isWhitespace {
                index += 1
                continue
            }

            if character == "," || character == "." || character == ";" {
                tokens.append(
                    CommandToken(
                        kind: .punctuation(String(character)),
                        span: SourceSpan(start: index, end: index + 1),
                        original: String(character)
                    )
                )
                index += 1
                continue
            }

            if character.isNumber {
                var end = index
                var literal = ""
                while end < characters.count, characters[end].isNumber || characters[end] == "." {
                    literal.append(characters[end])
                    end += 1
                }
                tokens.append(
                    CommandToken(
                        kind: .number(Double(literal) ?? 0),
                        span: SourceSpan(start: index, end: end),
                        original: literal
                    )
                )
                index = end
                continue
            }

            if character.isLetter {
                var end = index
                var literal = ""
                while end < characters.count {
                    let next = characters[end]
                    if next.isLetter || next.isNumber || next == "-" || next == "_" {
                        literal.append(next)
                        end += 1
                    } else {
                        break
                    }
                }
                tokens.append(
                    CommandToken(
                        kind: .word(literal.lowercased()),
                        span: SourceSpan(start: index, end: end),
                        original: literal
                    )
                )
                index = end
                continue
            }

            tokens.append(
                CommandToken(
                    kind: .punctuation(String(character)),
                    span: SourceSpan(start: index, end: index + 1),
                    original: String(character)
                )
            )
            index += 1
        }

        return tokens
    }
}

public struct CommandParser: Sendable {
    public init() {}

    public func parse(_ text: String) -> ParsedCommand {
        var worker = ParserWorker(tokens: CommandTokenizer.tokenize(text), text: text)
        return worker.parse()
    }
}

private struct ParserWorker {
    let tokens: [CommandToken]
    let text: String
    var position = 0

    static let connectors: Set<String> = ["and", "then", "also", ","]
    static let clauseKeywords: Set<String> = ["open", "wait", "show", "notify"]
    static let timeUnits: Set<String> = ["second", "seconds", "sec", "secs", "s"]
    static let excluded: [String: String] = [
        "email": "Sending email is not supported in this release.",
        "send": "Sending messages is not supported in this release.",
        "message": "Messaging is not supported in this release.",
        "delete": "Deleting or moving files is not supported in this release.",
        "remove": "Deleting or moving files is not supported in this release.",
        "move": "Deleting or moving files is not supported in this release.",
        "rename": "Renaming files is not supported in this release.",
        "run": "Running scripts or shell commands is not supported in this release.",
        "execute": "Running scripts or shell commands is not supported in this release.",
        "script": "Running scripts is not supported in this release.",
        "applescript": "AppleScript is not supported in this release.",
        "shortcut": "Running Apple Shortcuts is not supported in this release.",
        "click": "Simulating clicks is not supported in this release.",
        "type": "Sending keystrokes is not supported in this release.",
        "upload": "Uploading is not supported in this release.",
        "download": "Downloading is not supported in this release.",
    ]

    mutating func parse() -> ParsedCommand {
        var clauses: [ParsedClause] = []
        var diagnosticList: [ParseDiagnostic] = []

        skipConnectors()
        while position < tokens.count {
            let start = position
            let clause = parseClause()
            clauses.append(clause)
            diagnosticList.append(contentsOf: diagnostics(for: clause))
            skipConnectors()
            if position == start {
                position += 1
            }
        }

        return ParsedCommand(
            text: text,
            clauses: clauses,
            diagnostics: diagnosticList,
            outcome: Self.outcome(for: clauses, diagnostics: diagnosticList)
        )
    }

    private static func outcome(for clauses: [ParsedClause], diagnostics: [ParseDiagnostic]) -> ParseOutcome {
        if clauses.isEmpty {
            return .needsInput
        }
        if clauses.contains(where: { $0.kind == .unsupported }) {
            return .unsupported
        }
        if clauses.contains(where: { $0.kind == .unrecognized }) {
            return .unrecognized
        }
        if clauses.contains(where: needsInput) {
            return .needsInput
        }
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .needsInput
        }
        return .complete
    }

    private static func needsInput(_ clause: ParsedClause) -> Bool {
        switch clause.kind {
        case .openApplication:
            return clause.resourceNames.isEmpty
        case .wait:
            guard let duration = clause.duration else { return true }
            return !WaitAction.allowedRange.contains(duration)
        case .showNotification, .unsupported, .unrecognized:
            return false
        }
    }

    private func diagnostics(for clause: ParsedClause) -> [ParseDiagnostic] {
        switch clause.kind {
        case .openApplication where clause.resourceNames.isEmpty:
            return [.error("Open needs an application name.", span: clause.span)]
        case .wait:
            guard let duration = clause.duration else {
                return [.error("Wait needs a duration, for example 5 seconds.", span: clause.span)]
            }
            if !WaitAction.allowedRange.contains(duration) {
                return [.error("Wait must be between 0.1 and 30 seconds.", span: clause.span)]
            }
            return []
        case .unsupported:
            return [.error(clause.detail ?? "This capability is not supported in this release.", span: clause.span)]
        case .unrecognized:
            return [.warning("Could not match supported wording.", span: clause.span)]
        default:
            return []
        }
    }

    private mutating func parseClause() -> ParsedClause {
        guard position < tokens.count else {
            return ParsedClause(kind: .unrecognized, span: SourceSpan(start: 0, end: 0), parameter: .none, detail: nil)
        }

        let token = tokens[position]
        guard case .word(let word) = token.kind else {
            position += 1
            return ParsedClause(kind: .unrecognized, span: token.span, parameter: .none, detail: nil)
        }

        switch word {
        case "open":
            return parseOpen()
        case "wait":
            return parseWait()
        case "show", "notify":
            return parseNotification()
        default:
            if let reason = Self.excluded[word] {
                return parseUnsupported(reason: reason)
            }
            return parseUnrecognized()
        }
    }

    private mutating func parseOpen() -> ParsedClause {
        let openToken = tokens[position]
        position += 1

        var names: [String] = []
        var currentWords: [String] = []
        var end = openToken.span.end

        func flush() {
            let joined = currentWords.joined(separator: " ")
            if !joined.isEmpty {
                names.append(joined)
            }
            currentWords.removeAll()
        }

        while position < tokens.count {
            let token = tokens[position]

            switch token.kind {
            case .word(let word):
                if Self.connectors.contains(word) {
                    if isClauseStart(tokenAfterCurrent) {
                        flush()
                        return openClause(names: names, start: openToken.span.start, end: end)
                    }
                    flush()
                    end = token.span.end
                    position += 1
                    continue
                }
                currentWords.append(token.original)
                end = token.span.end
                position += 1

            case .punctuation(let punctuation):
                if punctuation == "," {
                    flush()
                    end = token.span.end
                    position += 1
                    continue
                }
                flush()
                return openClause(names: names, start: openToken.span.start, end: end)

            case .number:
                currentWords.append(token.original)
                end = token.span.end
                position += 1
            }
        }

        flush()
        return openClause(names: names, start: openToken.span.start, end: end)
    }

    private func openClause(names: [String], start: Int, end: Int) -> ParsedClause {
        ParsedClause(
            kind: .openApplication,
            span: SourceSpan(start: start, end: end),
            parameter: .resourceNames(names),
            detail: nil
        )
    }

    private mutating func parseWait() -> ParsedClause {
        let waitToken = tokens[position]
        position += 1
        var end = waitToken.span.end

        if position < tokens.count, case .word(let word) = tokens[position].kind, word == "for" {
            end = tokens[position].span.end
            position += 1
        }

        guard position < tokens.count, case .number(let value) = tokens[position].kind else {
            return ParsedClause(
                kind: .wait,
                span: SourceSpan(start: waitToken.span.start, end: end),
                parameter: .none,
                detail: nil
            )
        }

        end = tokens[position].span.end
        position += 1

        if position < tokens.count, case .word(let unit) = tokens[position].kind, Self.timeUnits.contains(unit) {
            end = tokens[position].span.end
            position += 1
        }

        return ParsedClause(
            kind: .wait,
            span: SourceSpan(start: waitToken.span.start, end: end),
            parameter: .duration(value),
            detail: nil
        )
    }

    private mutating func parseNotification() -> ParsedClause {
        let startToken = tokens[position]
        guard case .word(let word) = startToken.kind else {
            position += 1
            return ParsedClause(kind: .unrecognized, span: startToken.span, parameter: .none, detail: nil)
        }
        position += 1
        var end = startToken.span.end

        if word == "notify" {
            return ParsedClause(
                kind: .showNotification,
                span: SourceSpan(start: startToken.span.start, end: end),
                parameter: .none,
                detail: nil
            )
        }

        if position < tokens.count, case .word(let article) = tokens[position].kind, article == "a" {
            end = tokens[position].span.end
            position += 1
        }

        if position < tokens.count, case .word(let noun) = tokens[position].kind, noun == "notification" {
            end = tokens[position].span.end
            position += 1
            return ParsedClause(
                kind: .showNotification,
                span: SourceSpan(start: startToken.span.start, end: end),
                parameter: .none,
                detail: nil
            )
        }

        return ParsedClause(
            kind: .unrecognized,
            span: SourceSpan(start: startToken.span.start, end: end),
            parameter: .none,
            detail: nil
        )
    }

    private mutating func parseUnsupported(reason: String) -> ParsedClause {
        let startToken = tokens[position]
        let end = consumeClauseRemainder()
        return ParsedClause(
            kind: .unsupported,
            span: SourceSpan(start: startToken.span.start, end: end),
            parameter: .none,
            detail: reason
        )
    }

    private mutating func parseUnrecognized() -> ParsedClause {
        let startToken = tokens[position]
        let end = consumeClauseRemainder()
        return ParsedClause(
            kind: .unrecognized,
            span: SourceSpan(start: startToken.span.start, end: end),
            parameter: .none,
            detail: nil
        )
    }

    private mutating func consumeClauseRemainder() -> Int {
        var end = tokens[position].span.end
        position += 1
        while position < tokens.count {
            if isConnectorToken(tokens[position]), isClauseStart(tokenAfterCurrent) {
                break
            }
            end = tokens[position].span.end
            position += 1
        }
        return end
    }

    private var tokenAfterCurrent: CommandToken? {
        let next = position + 1
        guard next < tokens.count else { return nil }
        return tokens[next]
    }

    private func isClauseStart(_ token: CommandToken?) -> Bool {
        guard let token, case .word(let word) = token.kind else {
            return false
        }
        return Self.clauseKeywords.contains(word) || Self.excluded[word] != nil
    }

    private func isConnectorToken(_ token: CommandToken) -> Bool {
        switch token.kind {
        case .word(let word):
            return Self.connectors.contains(word)
        case .punctuation(let punctuation):
            return punctuation == ","
        case .number:
            return false
        }
    }

    private mutating func skipConnectors() {
        while position < tokens.count, isConnectorToken(tokens[position]) {
            position += 1
        }
    }
}
