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
    private static let wordExtras: Set<Character> = [
        ".", "-", "_", "/", ":", "?", "=", "%", "&", "#", "@", "~", "+",
    ]
    private static let punctuation: Set<Character> = [",", ".", ";"]

    static func tokenize(_ input: String) -> [CommandToken] {
        var tokens: [CommandToken] = []
        var index = input.startIndex
        var offset = 0

        while index < input.endIndex {
            let character = input[index]

            if character.isWhitespace {
                offset += utf16Length(character)
                index = input.index(after: index)
                continue
            }

            if punctuation.contains(character) {
                let length = utf16Length(character)
                tokens.append(
                    CommandToken(
                        kind: .punctuation(String(character)),
                        span: SourceSpan(start: offset, end: offset + length),
                        original: String(character)
                    )
                )
                offset += length
                index = input.index(after: index)
                continue
            }

            if character.isNumber {
                var literal = ""
                while index < input.endIndex, input[index].isNumber || input[index] == "." {
                    literal.append(input[index])
                    index = input.index(after: index)
                }
                let length = literal.utf16.count
                tokens.append(
                    CommandToken(
                        kind: .number(Double(literal) ?? 0),
                        span: SourceSpan(start: offset, end: offset + length),
                        original: literal
                    )
                )
                offset += length
                continue
            }

            if character.isLetter {
                var literal = ""
                while index < input.endIndex {
                    let next = input[index]
                    if next.isLetter || next.isNumber || Self.wordExtras.contains(next) {
                        literal.append(next)
                        index = input.index(after: index)
                    } else {
                        break
                    }
                }
                let length = literal.utf16.count
                tokens.append(
                    CommandToken(
                        kind: .word(literal.lowercased()),
                        span: SourceSpan(start: offset, end: offset + length),
                        original: literal
                    )
                )
                offset += length
                continue
            }

            let length = utf16Length(character)
            tokens.append(
                CommandToken(
                    kind: .punctuation(String(character)),
                    span: SourceSpan(start: offset, end: offset + length),
                    original: String(character)
                )
            )
            offset += length
            index = input.index(after: index)
        }

        return tokens
    }

    private static func utf16Length(_ character: Character) -> Int {
        String(character).utf16.count
    }
}

public struct CommandParser: Sendable {
    public let language: CommandLanguageCatalog

    public init(language: CommandLanguageCatalog = .standard) {
        self.language = language
    }

    public func parse(_ text: String) -> ParsedCommand {
        if text.count > CommandLimits.maximumCharacters {
            return Self.limitFailure(text, message: "Commands must be 2,000 characters or fewer.")
        }
        if text.utf16.count > CommandLimits.maximumUTF16Units {
            return Self.limitFailure(text, message: "Commands must be 16,384 UTF-16 units or fewer.")
        }

        let rawTokens = CommandTokenizer.tokenize(text)
        if rawTokens.count > CommandLimits.maximumTokens {
            return Self.limitFailure(text, message: "Commands must be 128 words or fewer.")
        }
        let tokens = Self.splittingFinalPunctuation(rawTokens, text: text)

        var worker = ParserWorker(tokens: tokens, text: text, language: language)
        return worker.parse()
    }

    static func limitFailure(_ text: String, message: String) -> ParsedCommand {
        let span = SourceSpan(start: 0, end: text.utf16.count)
        return ParsedCommand(
            text: text,
            clauses: [],
            diagnostics: [.error(message, span: span)],
            outcome: .needsInput,
            coverage: SourceCoverage(coveredSpans: [], unresolvedSpans: [span]),
            clarifications: [ParseClarification(span: span, question: message)]
        )
    }

    static func splittingFinalPunctuation(_ tokens: [CommandToken], text: String) -> [CommandToken] {
        guard let last = tokens.last,
              !isInsideUnclosedLiteral(text),
              let final = last.original.last,
              [".", "?", "!"].contains(final) else {
            return tokens
        }

        let base = String(last.original.dropLast())
        guard !base.isEmpty else { return tokens }

        let splitKind: CommandToken.Kind
        switch last.kind {
        case .word:
            splitKind = .word(base.lowercased())
        case .number:
            splitKind = .number(Double(base) ?? 0)
        case .punctuation:
            return tokens
        }

        let length = String(final).utf16.count
        var result = tokens
        result.removeLast()
        result.append(
            CommandToken(
                kind: splitKind,
                span: SourceSpan(start: last.span.start, end: last.span.end - length),
                original: base
            )
        )
        result.append(
            CommandToken(
                kind: .punctuation(String(final)),
                span: SourceSpan(start: last.span.end - length, end: last.span.end),
                original: String(final)
            )
        )
        return result
    }

    static func isInsideUnclosedLiteral(_ text: String) -> Bool {
        var open = false
        var escaped = false
        for character in text {
            if escaped {
                escaped = false
                continue
            }
            if character == "\\" {
                escaped = true
                continue
            }
            if character == "\"" {
                open.toggle()
            }
        }
        return open
    }
}

private struct ParserWorker {
    let tokens: [CommandToken]
    let text: String
    let language: CommandLanguageCatalog
    var position = 0

    private let clauseStarts: Set<String>

    init(tokens: [CommandToken], text: String, language: CommandLanguageCatalog) {
        self.tokens = tokens
        self.text = text
        self.language = language
        self.clauseStarts = language.clauseStartWords()
    }

    func displayEvent(for phrase: String) -> DisplayEvent? {
        for subject in language.trigger.displaySubjects {
            for word in language.trigger.displayConnectWords where phrase == "\(subject) \(word)" {
                return .connected
            }
            for word in language.trigger.displayDisconnectWords where phrase == "\(subject) \(word)" {
                return .disconnected
            }
        }
        return nil
    }

    func volumeEvent(for phrase: String) -> VolumeEvent? {
        for subject in language.trigger.volumeSubjects {
            for word in language.trigger.volumeMountWords where phrase == "\(subject) \(word)" {
                return .mounted
            }
            for word in language.trigger.volumeUnmountWords where phrase == "\(subject) \(word)" {
                return .unmounted
            }
        }
        return nil
    }

    func powerEvent(for phrase: String) -> PowerEvent? {
        for subject in language.trigger.powerSubjects {
            for suffix in language.trigger.powerToBatterySuffixes where phrase == "\(subject) \(suffix)" {
                return .toBattery
            }
            for suffix in language.trigger.powerToExternalSuffixes where phrase == "\(subject) \(suffix)" {
                return .toExternalPower
            }
        }
        return nil
    }

    func batteryThreshold(for phrase: String) -> (comparator: ThresholdComparison, percentage: Int)? {
        for subject in language.trigger.batterySubjects {
            for word in language.trigger.batteryBelowWords where phrase.hasPrefix("\(subject) \(word) ") {
                let value = phrase.dropFirst("\(subject) \(word) ".count)
                if let percentage = Int(value) { return (.below, percentage) }
            }
            for word in language.trigger.batteryAboveWords where phrase.hasPrefix("\(subject) \(word) ") {
                let value = phrase.dropFirst("\(subject) \(word) ".count)
                if let percentage = Int(value) { return (.above, percentage) }
            }
        }
        return nil
    }

    mutating func parse() -> ParsedCommand {
        var clauses: [ParsedClause] = []
        var diagnosticList: [ParseDiagnostic] = []
        var approvedSpans: [SourceSpan] = []

        var effectiveEnd = text.utf16.count

        if let frameEnd = language.leadingFrameEnd(in: text), frameEnd > 0 {
            approvedSpans.append(SourceSpan(start: 0, end: frameEnd))
            while position < tokens.count, tokens[position].span.start < frameEnd {
                position += 1
            }
        }

        if let rationale = language.rationaleSpan(in: text) {
            approvedSpans.append(rationale)
            effectiveEnd = rationale.start
        } else if let last = tokens.last,
                  case .punctuation(let punctuation) = last.kind,
                  punctuation.count == 1,
                  let character = punctuation.first,
                  language.isFinalPunctuation(character) {
            approvedSpans.append(last.span)
            effectiveEnd = min(effectiveEnd, last.span.start)
        }

        skipConnectors()
        while position < tokens.count, tokens[position].span.start < effectiveEnd {
            let start = position
            let clause = parseClause()
            clauses.append(clause)
            diagnosticList.append(contentsOf: diagnostics(for: clause))
            skipConnectors()
            if position == start {
                position += 1
            }
        }

        if let lastClause = clauses.last,
           lastClause.kind == .unrecognized,
           lastClause.span.length == 1,
           let raw = text.substring(in: lastClause.span),
           raw.count == 1,
           let character = raw.first,
           language.isFinalPunctuation(character) {
            approvedSpans.append(lastClause.span)
            clauses.removeLast()
        }

        var clarifications: [ParseClarification] = []
        for clause in clauses where clause.kind == .copyText {
            guard (clause.copyText ?? "").isEmpty,
                  let raw = text.substring(in: clause.span) else {
                continue
            }
            let quoteCount = raw.filter { $0 == "\"" }.count
            if quoteCount % 2 == 1 {
                clarifications.append(
                    ParseClarification(span: clause.span, question: "Close the quote to finish the text.")
                )
            }
        }

        let triggerIndices = clauses.indices.filter { Self.isTriggerClause(clauses[$0]) }
        if triggerIndices.count > 1 {
            diagnosticList.append(
                .error("Use only one trigger.", span: clauses[triggerIndices[1]].span)
            )
        } else if let index = triggerIndices.first, index != 0, index != clauses.count - 1 {
            diagnosticList.append(
                .error("Put the trigger at the start or the end of the command.", span: clauses[index].span)
            )
        }

        let coverage = coverage(for: clauses, approved: approvedSpans)
        var outcome = Self.outcome(for: clauses, diagnostics: diagnosticList)

        if !coverage.isComplete {
            diagnosticList.append(
                .error("Some text was not understood.", span: coverage.unresolvedSpans.first)
            )
            if outcome == .complete {
                outcome = .needsInput
            }
        }

        let actionCount = clauses.reduce(0) { count, clause in
            switch clause.kind {
            case .openApplication, .hideApplication, .quitApplication:
                return count + max(1, clause.resourceNames.count)
            case .openFile, .revealInFinder, .arrangeWindow, .wait, .showNotification, .copyText:
                return count + 1
            default:
                return count
            }
        }
        if actionCount > CommandLimits.maximumActions {
            diagnosticList.append(.error("A workflow can have at most 12 steps.", span: nil))
            if outcome == .complete {
                outcome = .needsInput
            }
        }

        return ParsedCommand(
            text: text,
            clauses: clauses,
            diagnostics: diagnosticList,
            outcome: outcome,
            coverage: coverage,
            clarifications: clarifications
        )
    }

    func coverage(for clauses: [ParsedClause], approved: [SourceSpan] = []) -> SourceCoverage {
        let covered = (clauses.map(\.span) + approved).filter { $0.length > 0 }
        var unresolved: [SourceSpan] = []

        for token in tokens {
            if isConnectorToken(token) {
                let isInside = covered.contains { span in
                    span.start <= token.span.start && token.span.end <= span.end
                }
                let leadsToCoveredSpan = covered.contains { span in
                    span.start >= token.span.end
                }
                if !isInside && !leadsToCoveredSpan {
                    unresolved.append(token.span)
                }
                continue
            }

            let isCovered = covered.contains { span in
                span.start <= token.span.start && token.span.end <= span.end
            }
            if !isCovered {
                unresolved.append(token.span)
            }
        }

        return SourceCoverage(coveredSpans: Self.merge(covered), unresolvedSpans: Self.merge(unresolved))
    }

    private static func merge(_ spans: [SourceSpan]) -> [SourceSpan] {
        let sorted = spans.sorted { $0.start < $1.start }
        var result: [SourceSpan] = []
        for span in sorted {
            if let last = result.last, span.start <= last.end {
                result[result.count - 1] = SourceSpan(start: last.start, end: max(last.end, span.end))
            } else {
                result.append(span)
            }
        }
        return result
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

    private static func isTriggerClause(_ clause: ParsedClause) -> Bool {
        switch clause.kind {
        case .schedule, .applicationLifecycle, .wake, .displayConnection,
             .externalVolume, .powerSource, .batteryThreshold:
            return true
        default:
            return false
        }
    }

    private static func needsInput(_ clause: ParsedClause) -> Bool {
        switch clause.kind {
        case .openApplication:
            return clause.resourceNames.isEmpty
        case .hideApplication, .quitApplication:
            return clause.resourceNames.isEmpty
        case .openFile, .revealInFinder:
            return clause.fileSelectionKind == nil
        case .applicationLifecycle:
            let name = (clause.lifecycleApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return clause.lifecycleEvent == nil || name.isEmpty
        case .wake, .displayConnection, .externalVolume, .powerSource, .batteryThreshold:
            return false
        case .arrangeWindow:
            let name = clause.arrangeApplicationName ?? ""
            return clause.arrangePreset == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .wait:
            guard let duration = clause.duration else { return true }
            return !WaitAction.allowedRange.contains(duration)
        case .schedule:
            return clause.schedule == .incomplete
        case .copyText:
            return (clause.copyText ?? "").isEmpty
        case .showNotification, .unsupported, .unrecognized:
            return false
        }
    }

    private func diagnostics(for clause: ParsedClause) -> [ParseDiagnostic] {
        switch clause.kind {
        case .openApplication where clause.resourceNames.isEmpty:
            return [.error("Open needs an application name.", span: clause.span)]
        case .hideApplication where clause.resourceNames.isEmpty:
            return [.error("Hide needs an application name.", span: clause.span)]
        case .quitApplication where clause.resourceNames.isEmpty:
            return [.error("Quit needs an application name.", span: clause.span)]
        case .openFile, .revealInFinder:
            if clause.fileSelectionKind == nil {
                return [.error("Choose a file or folder for this step.", span: clause.span)]
            }
            return []
        case .applicationLifecycle:
            var issues: [ParseDiagnostic] = []
            let name = (clause.lifecycleApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                issues.append(.error("Name the application to watch.", span: clause.span))
            }
            if clause.lifecycleEvent == nil {
                issues.append(.error("Say whether the app opens or quits.", span: clause.span))
            }
            return issues
        case .wait:
            guard let duration = clause.duration else {
                return [.error("Wait needs a duration, for example 5 seconds.", span: clause.span)]
            }
            if !WaitAction.allowedRange.contains(duration) {
                return [.error("Wait must be between 0.1 and 30 seconds.", span: clause.span)]
            }
            return []
        case .arrangeWindow:
            var issues: [ParseDiagnostic] = []
            let name = (clause.arrangeApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                issues.append(.error("Arrange Window needs an application name.", span: clause.span))
            }
            if clause.arrangePreset == nil {
                issues.append(.error("Arrange Window needs a position, for example the left half.", span: clause.span))
            }
            return issues
        case .schedule:
            if clause.schedule == .incomplete {
                return [.error("Specify a time, for example every day at 9 am, or in 30 minutes.", span: clause.span)]
            }
            return []
        case .copyText:
            if (clause.copyText ?? "").isEmpty {
                return [.error("Copy needs the text to place on the clipboard.", span: clause.span)]
            }
            return []
        case .unsupported:
            return [.error(clause.detail ?? "This capability is not supported in this release.", span: clause.span)]
        case .unrecognized:
            if let detail = clause.detail {
                return [.error(detail, span: clause.span)]
            }
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

        if word == language.schedule.atWord, let friendly = parseFriendlySchedule() {
            return friendly
        }

        if let route = language.clauseRoutes[word] {
            switch route {
            case .open:
                return parseOpen()
            case .hideApplication:
                return parseApplicationListClause(kind: .hideApplication)
            case .quitApplication:
                return parseApplicationListClause(kind: .quitApplication)
            case .reveal:
                return parseReveal()
            case .wait:
                return parseWait()
            case .notification:
                return parseNotification()
            case .copy:
                return parseCopy()
            case .arrange:
                return parseArrange()
            case .maximize:
                return parseArrangeWithFixedPreset(.maximize)
            case .center:
                return parseArrangeWithFixedPreset(.center)
            case .schedule:
                return parseSchedule()
            case .when:
                return parseWhen()
            }
        }

        if language.shared.negationWords.contains(word) {
            return parseNegated()
        }

        if let reason = language.excluded[word] {
            return parseUnsupported(reason: reason)
        }
        return parseUnrecognized()
    }

    private mutating func parseNegated() -> ParsedClause {
        let startToken = tokens[position]
        let end = consumeClauseRemainder()
        return ParsedClause(
            kind: .unrecognized,
            span: SourceSpan(start: startToken.span.start, end: end),
            parameter: .none,
            detail: "Negated actions are not supported."
        )
    }

    private mutating func parseOpen() -> ParsedClause {
        let openToken = tokens[position]
        position += 1
        let (names, end) = collectApplicationNames(after: openToken)

        let joined = names.joined(separator: " ").lowercased()
        let kind = language.file.selectionPhrases[joined]

        if let kind {
            return ParsedClause(
                kind: .openFile,
                span: SourceSpan(start: openToken.span.start, end: end),
                parameter: .fileSelection(kind: kind),
                detail: nil
            )
        }

        return ParsedClause(
            kind: .openApplication,
            span: SourceSpan(start: openToken.span.start, end: end),
            parameter: .resourceNames(names),
            detail: nil
        )
    }

    private mutating func parseReveal() -> ParsedClause {
        let keyword = tokens[position]
        position += 1
        let (names, end) = collectApplicationNames(after: keyword)
        let joined = names.joined(separator: " ").lowercased()

        if language.file.revealPhrases.contains(joined) {
            return ParsedClause(
                kind: .revealInFinder,
                span: SourceSpan(start: keyword.span.start, end: end),
                parameter: .fileSelection(kind: .file),
                detail: nil
            )
        }

        return ParsedClause(
            kind: .revealInFinder,
            span: SourceSpan(start: keyword.span.start, end: end),
            parameter: .none,
            detail: nil
        )
    }

    private mutating func parseApplicationListClause(kind: ParsedClauseKind) -> ParsedClause {
        let keyword = tokens[position]
        position += 1
        let (names, end) = collectApplicationNames(after: keyword)
        return ParsedClause(
            kind: kind,
            span: SourceSpan(start: keyword.span.start, end: end),
            parameter: .resourceNames(names),
            detail: nil
        )
    }

    private mutating func collectApplicationNames(after keyword: CommandToken) -> ([String], Int) {
        var names: [String] = []
        var currentWords: [String] = []
        var end = keyword.span.end

        func flush() {
            let joined = currentWords.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,;"))
            if !joined.isEmpty {
                names.append(joined)
            }
            currentWords.removeAll()
        }

        while position < tokens.count {
            let token = tokens[position]

            switch token.kind {
            case .word(let word):
                if language.isRationaleMarker(word) {
                    flush()
                    return (names, end)
                }

                if let connector = listConnector(at: position) {
                    let nextIndex = position + connector.tokenCount
                    if nextIndex >= tokens.count {
                        flush()
                        return (names, end)
                    }
                    flush()
                    end = tokens[nextIndex - 1].span.end
                    position = nextIndex
                    if isClauseStart(tokens[nextIndex]) {
                        return (names, end)
                    }
                    continue
                }

                if isClauseStart(token), !currentWords.isEmpty || !names.isEmpty {
                    flush()
                    return (names, end)
                }

                currentWords.append(token.original)
                end = token.span.end
                position += 1

            case .punctuation(let punctuation):
                if punctuation == "\"" {
                    switch CommandLiteralScanner.scan(text, at: token.span.start) {
                    case .success(let literal):
                        flush()
                        names.append(literal.value)
                        end = max(end, literal.span.end)
                        advancePastLiteral(literal.span)
                        continue
                    case .failure:
                        flush()
                        end = token.span.end
                        position += 1
                        return (names, end)
                    }
                }
                if let connector = listConnector(at: position) {
                    let nextIndex = position + connector.tokenCount
                    if nextIndex >= tokens.count {
                        flush()
                        return (names, end)
                    }
                    flush()
                    end = tokens[nextIndex - 1].span.end
                    position = nextIndex
                    if isClauseStart(tokens[nextIndex]) {
                        return (names, end)
                    }
                    continue
                }
                flush()
                return (names, end)

            case .number:
                currentWords.append(token.original)
                end = token.span.end
                position += 1
            }
        }

        flush()
        return (names, end)
    }

    private struct ListConnector {
        let tokenCount: Int
    }

    private func listConnector(at index: Int) -> ListConnector? {
        guard index >= 0, index < tokens.count else { return nil }

        switch tokens[index].kind {
        case .punctuation(let punctuation):
            return language.shared.connectorPunctuation.contains(punctuation)
                ? ListConnector(tokenCount: 1)
                : nil

        case .word(let word):
            if language.shared.listSeparatorWords.contains(word) {
                return ListConnector(tokenCount: 1)
            }
            for phrase in language.shared.clauseConnectorPhrases where phrase.first == word {
                var matches = true
                for (offset, expected) in phrase.enumerated() {
                    guard index + offset < tokens.count,
                          case .word(let candidate) = tokens[index + offset].kind,
                          candidate == expected else {
                        matches = false
                        break
                    }
                }
                guard matches,
                      let next = token(at: index + phrase.count),
                      isClauseStart(next) else {
                    continue
                }
                return ListConnector(tokenCount: phrase.count)
            }
            return nil

        case .number:
            return nil
        }
    }

    private func token(at index: Int) -> CommandToken? {
        guard index >= 0, index < tokens.count else { return nil }
        return tokens[index]
    }

    private mutating func parseArrange() -> ParsedClause {
        let startToken = tokens[position]
        position += 1

        var appWords: [String] = []
        var end = startToken.span.end
        var preset: WindowPreset?

        while position < tokens.count {
            let token = tokens[position]
            if case .punctuation(let punctuation) = token.kind, punctuation == "\"" {
                if case .success(let literal) = CommandLiteralScanner.scan(text, at: token.span.start) {
                    appWords = [literal.value]
                    end = max(end, literal.span.end)
                    advancePastLiteral(literal.span)
                    continue
                }
                break
            }
            guard case .word(let word) = token.kind else { break }
            if isConnectorWord(word) || language.isRationaleMarker(word) { break }
            if language.arrange.joiners.contains(word) {
                let (found, newEnd) = parsePresetPhrase()
                if let found {
                    preset = found
                }
                end = max(end, newEnd)
                break
            }
            appWords.append(token.original)
            end = token.span.end
            position += 1
        }

        return arrangeClause(
            applicationName: appWords.joined(separator: " "),
            preset: preset,
            start: startToken.span.start,
            end: end
        )
    }

    private mutating func parseArrangeWithFixedPreset(_ preset: WindowPreset) -> ParsedClause {
        let startToken = tokens[position]
        position += 1

        var appWords: [String] = []
        var end = startToken.span.end

        while position < tokens.count {
            let token = tokens[position]
            if case .punctuation(let punctuation) = token.kind, punctuation == "\"" {
                if case .success(let literal) = CommandLiteralScanner.scan(text, at: token.span.start) {
                    appWords = [literal.value]
                    end = max(end, literal.span.end)
                    advancePastLiteral(literal.span)
                    continue
                }
                break
            }
            guard case .word(let word) = token.kind else { break }
            if isConnectorWord(word) || language.isRationaleMarker(word) || language.arrange.joiners.contains(word) { break }
            appWords.append(token.original)
            end = token.span.end
            position += 1
        }

        return arrangeClause(
            applicationName: appWords.joined(separator: " "),
            preset: preset,
            start: startToken.span.start,
            end: end
        )
    }

    private func arrangeClause(applicationName: String, preset: WindowPreset?, start: Int, end: Int) -> ParsedClause {
        let trimmed = applicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedClause(
            kind: .arrangeWindow,
            span: SourceSpan(start: start, end: end),
            parameter: .arrange(preset: preset, applicationName: trimmed),
            detail: nil
        )
    }

    private mutating func parsePresetPhrase() -> (WindowPreset?, Int) {
        var end = tokens[position].span.end
        position += 1

        if position < tokens.count, case .word(let article) = tokens[position].kind,
           language.arrange.articles.contains(article) {
            end = tokens[position].span.end
            position += 1
        }

        guard position < tokens.count, case .word(let side) = tokens[position].kind else {
            return (nil, end)
        }
        end = tokens[position].span.end
        position += 1

        guard language.arrange.sides.contains(side) else {
            return (nil, end)
        }

        let arrange = language.arrange

        if side == arrange.leftWord || side == arrange.rightWord {
            if position < tokens.count, case .word(let noun) = tokens[position].kind,
               arrange.halfNouns.contains(noun) {
                end = tokens[position].span.end
                position += 1
            }
            return (side == arrange.leftWord ? .leftHalf : .rightHalf, end)
        }

        if side == arrange.topWord || side == arrange.bottomWord {
            if position < tokens.count, case .word(let horizontal) = tokens[position].kind,
               arrange.horizontalSides.contains(horizontal) {
                end = tokens[position].span.end
                position += 1
                let preset: WindowPreset
                if side == arrange.topWord, horizontal == arrange.leftWord {
                    preset = .topLeftQuarter
                } else if side == arrange.topWord, horizontal == arrange.rightWord {
                    preset = .topRightQuarter
                } else if side == arrange.bottomWord, horizontal == arrange.leftWord {
                    preset = .bottomLeftQuarter
                } else {
                    preset = .bottomRightQuarter
                }
                return (preset, end)
            }
            if position < tokens.count, case .word(let noun) = tokens[position].kind,
               arrange.halfNouns.contains(noun) {
                end = tokens[position].span.end
                position += 1
            }
            return (side == arrange.topWord ? .topHalf : .bottomHalf, end)
        }

        return (nil, end)
    }

    private mutating func parseWait() -> ParsedClause {
        let waitToken = tokens[position]
        position += 1
        var end = waitToken.span.end

        if position < tokens.count, case .word(let word) = tokens[position].kind,
           language.wait.optionalWords.contains(word) {
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

        if position < tokens.count, case .word(let unit) = tokens[position].kind,
           language.wait.timeUnits.contains(unit) {
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

        if language.notification.directWords.contains(word) {
            return ParsedClause(
                kind: .showNotification,
                span: SourceSpan(start: startToken.span.start, end: end),
                parameter: .none,
                detail: nil
            )
        }

        if position < tokens.count, case .word(let article) = tokens[position].kind,
           language.notification.articles.contains(article) {
            end = tokens[position].span.end
            position += 1
        }

        if position < tokens.count, case .word(let noun) = tokens[position].kind,
           language.notification.nouns.contains(noun) {
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

    private mutating func parseWhen() -> ParsedClause {
        let keyword = tokens[position]
        position += 1
        var end = keyword.span.end
        var originals: [String] = []
        var lowerWords: [String] = []

        while position < tokens.count {
            let token = tokens[position]

            if isConnectorToken(token), isClauseStart(tokenAfterCurrent) {
                break
            }

            switch token.kind {
            case .word(let word):
                guard !isConnectorWord(word) else {
                    return whenClause(originals: originals, lowerWords: lowerWords, start: keyword.span.start, end: end)
                }
                originals.append(token.original)
                lowerWords.append(word)
                end = token.span.end
                position += 1
            case .number(let value):
                originals.append(String(Int(value)))
                lowerWords.append(String(Int(value)))
                end = token.span.end
                position += 1
                if position < tokens.count, case .punctuation("%") = tokens[position].kind {
                    end = tokens[position].span.end
                    position += 1
                }
            case .punctuation:
                return whenClause(originals: originals, lowerWords: lowerWords, start: keyword.span.start, end: end)
            }
        }

        return whenClause(originals: originals, lowerWords: lowerWords, start: keyword.span.start, end: end)
    }

    private func whenClause(originals: [String], lowerWords: [String], start: Int, end: Int) -> ParsedClause {
        let span = SourceSpan(start: start, end: end)
        let phrase = lowerWords.joined(separator: " ")
        let displayName = originals.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        if language.trigger.wakePhrases.contains(phrase) {
            return ParsedClause(kind: .wake, span: span, parameter: .wake, detail: nil)
        }

        if let event = displayEvent(for: phrase) {
            return ParsedClause(kind: .displayConnection, span: span, parameter: .display(event), detail: nil)
        }
        if let event = volumeEvent(for: phrase) {
            return ParsedClause(kind: .externalVolume, span: span, parameter: .volume(event), detail: nil)
        }
        if let event = powerEvent(for: phrase) {
            return ParsedClause(kind: .powerSource, span: span, parameter: .power(event), detail: nil)
        }
        if let threshold = batteryThreshold(for: phrase) {
            return ParsedClause(
                kind: .batteryThreshold,
                span: span,
                parameter: .battery(comparator: threshold.comparator, percentage: threshold.percentage),
                detail: nil
            )
        }

        if let last = lowerWords.last,
           let event = language.trigger.lifecycleVerbs[last],
           originals.count >= 2 {
            let name = originals.dropLast().joined(separator: " ")
            return ParsedClause(
                kind: .applicationLifecycle,
                span: span,
                parameter: .lifecycle(event: event, applicationName: name),
                detail: nil
            )
        }

        return ParsedClause(
            kind: .applicationLifecycle,
            span: span,
            parameter: .lifecycle(event: nil, applicationName: displayName),
            detail: nil
        )
    }

    private mutating func parseCopy() -> ParsedClause {
        let startToken = tokens[position]
        position += 1
        var end = startToken.span.end

        if position < tokens.count, case .word(let word) = tokens[position].kind,
           language.copy.optionalWords.contains(word) {
            end = tokens[position].span.end
            position += 1
        }

        guard position < tokens.count else {
            return copyClause(value: "", start: startToken.span.start, end: end)
        }

        let literalStart = tokens[position].span.start

        switch CommandLiteralScanner.scan(text, at: literalStart) {
        case .success(let literal):
            advancePastLiteral(literal.span)
            return copyClause(value: literal.value, start: startToken.span.start, end: literal.span.end)
        case .failure:
            position = tokens.count
            let literalEnd = tokens.last?.span.end ?? end
            return copyClause(value: "", start: startToken.span.start, end: literalEnd)
        }
    }

    private mutating func advancePastLiteral(_ span: SourceSpan) {
        while position < tokens.count, tokens[position].span.start < span.end {
            position += 1
        }
    }

    private func copyClause(value: String, start: Int, end: Int) -> ParsedClause {
        ParsedClause(
            kind: .copyText,
            span: SourceSpan(start: start, end: end),
            parameter: .copyText(value),
            detail: nil
        )
    }

    private mutating func parseFriendlySchedule() -> ParsedClause? {
        let saved = position
        let atToken = tokens[position]
        position += 1

        guard let clock = parseClock() else {
            position = saved
            return nil
        }
        guard position < tokens.count, case .word(let every) = tokens[position].kind,
              every == language.schedule.everyWord else {
            position = saved
            return nil
        }
        position += 1
        guard position < tokens.count, case .word(let dayWord) = tokens[position].kind,
              language.schedule.dayWords.contains(dayWord) else {
            position = saved
            return nil
        }
        var end = tokens[position].span.end
        position += 1

        if position < tokens.count, case .word(let subject) = tokens[position].kind,
           language.schedule.optionalSubjectWords.contains(subject) {
            end = tokens[position].span.end
            position += 1
        }

        return scheduleClause(
            .daily(hour: clock.hour, minute: clock.minute),
            start: atToken.span.start,
            end: end
        )
    }

    private mutating func parseSchedule() -> ParsedClause {
        let startToken = tokens[position]
        guard case .word(let keyword) = startToken.kind else {
            position += 1
            return ParsedClause(kind: .unrecognized, span: startToken.span, parameter: .none, detail: nil)
        }
        position += 1
        let end = startToken.span.end

        if keyword == language.schedule.inWord {
            if let (seconds, durationEnd) = parseDurationPhrase(allowBareUnit: false) {
                return scheduleClause(.relative(seconds), start: startToken.span.start, end: durationEnd)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if keyword == language.schedule.onceWord {
            if position < tokens.count, case .word(let onWord) = tokens[position].kind,
               onWord == language.schedule.onWord {
                position += 1
                return parseAbsoluteOnce(startToken: startToken, onToken: tokens[max(0, position - 1)])
            }
            skipWord(language.schedule.atWord)
            if let clock = parseClock() {
                return scheduleClause(.once(hour: clock.hour, minute: clock.minute), start: startToken.span.start, end: clock.end)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        return parseEvery(startToken: startToken)
    }

    private mutating func parseAbsoluteOnce(startToken: CommandToken, onToken: CommandToken) -> ParsedClause {
        guard position < tokens.count else {
            return scheduleClause(.incomplete, start: startToken.span.start, end: onToken.span.end)
        }

        let scanStart = tokens[position].span.start
        guard let scanned = Self.scanAbsoluteDateTime(text, from: scanStart, atWord: language.schedule.atWord) else {
            let end = consumeClauseRemainder()
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        advancePastLiteral(SourceSpan(start: scanStart, end: scanned.end))
        let schedule: ParsedSchedule
        if Self.isValidAbsoluteDateTime(
            year: scanned.year,
            month: scanned.month,
            day: scanned.day,
            hour: scanned.hour,
            minute: scanned.minute
        ) {
            schedule = .absolute(
                year: scanned.year,
                month: scanned.month,
                day: scanned.day,
                hour: scanned.hour,
                minute: scanned.minute
            )
        } else {
            schedule = .incomplete
        }
        return scheduleClause(schedule, start: startToken.span.start, end: scanned.end)
    }

    private struct ScannedDateTime {
        let year: Int
        let month: Int
        let day: Int
        let hour: Int
        let minute: Int
        let end: Int
    }

    private static func scanAbsoluteDateTime(_ text: String, from offset: Int, atWord: String) -> ScannedDateTime? {
        guard let remainder = text.substring(in: SourceSpan(start: offset, end: text.utf16.count)) else {
            return nil
        }
        let characters = Array(remainder)
        var index = 0

        func readDigits(_ count: Int) -> Int? {
            guard index + count <= characters.count else { return nil }
            var value = 0
            for _ in 0..<count {
                let character = characters[index]
                guard character.isASCII, let digit = character.wholeNumberValue else { return nil }
                value = value * 10 + digit
                index += 1
            }
            return value
        }

        func consume(_ expected: Character) -> Bool {
            guard index < characters.count, characters[index] == expected else { return false }
            index += 1
            return true
        }

        func consumeWhitespace() -> Bool {
            let start = index
            while index < characters.count, characters[index].isWhitespace {
                index += 1
            }
            return index > start
        }

        func consumeWord(_ expected: String) -> Bool {
            let word = Array(expected)
            guard index + word.count <= characters.count else { return false }
            for character in word {
                guard characters[index] == character else { return false }
                index += 1
            }
            return true
        }

        guard let year = readDigits(4), consume("-"),
              let month = readDigits(2), consume("-"),
              let day = readDigits(2),
              consumeWhitespace(), consumeWord(atWord), consumeWhitespace(),
              let hour = readDigits(2), consume(":"),
              let minute = readDigits(2) else {
            return nil
        }

        if index < characters.count, characters[index].isNumber || characters[index] == ":" {
            return nil
        }

        let consumed = String(characters[0..<index]).utf16.count
        return ScannedDateTime(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            end: offset + consumed
        )
    }

    private static func isValidAbsoluteDateTime(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Bool {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return false }
        guard (1...12).contains(month), day >= 1 else { return false }

        let leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
        let monthLengths = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return day <= monthLengths[month - 1]
    }

    private mutating func parseEvery(startToken: CommandToken) -> ParsedClause {
        var end = startToken.span.end

        if position < tokens.count, case .number = tokens[position].kind {
            if let (seconds, durationEnd) = parseDurationPhrase(allowBareUnit: true) {
                return scheduleClause(.interval(seconds), start: startToken.span.start, end: durationEnd)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        guard position < tokens.count, case .word(let word) = tokens[position].kind else {
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if language.schedule.dayWords.contains(word) {
            end = tokens[position].span.end
            position += 1
            skipWord(language.schedule.atWord)
            if let clock = parseClock() {
                return scheduleClause(.daily(hour: clock.hour, minute: clock.minute), start: startToken.span.start, end: clock.end)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if language.schedule.weekdayWords.contains(word) {
            end = tokens[position].span.end
            position += 1
            skipWord(language.schedule.atWord)
            if let clock = parseClock() {
                return scheduleClause(
                    .weekdays(Weekday.weekdays, hour: clock.hour, minute: clock.minute),
                    start: startToken.span.start,
                    end: clock.end
                )
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if language.schedule.weekendWords.contains(word) {
            end = tokens[position].span.end
            position += 1
            skipWord(language.schedule.atWord)
            if let clock = parseClock() {
                return scheduleClause(
                    .weekdays(Weekday.weekend, hour: clock.hour, minute: clock.minute),
                    start: startToken.span.start,
                    end: clock.end
                )
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if let firstDay = language.schedule.weekdayNames[word] {
            var days: Set<Weekday> = [firstDay]
            end = tokens[position].span.end
            position += 1

            while true {
                let saved = position
                if position < tokens.count, isConnectorToken(tokens[position]) {
                    position += 1
                }
                guard position < tokens.count,
                      case .word(let next) = tokens[position].kind,
                      let day = language.schedule.weekdayNames[next] else {
                    position = saved
                    break
                }
                days.insert(day)
                end = tokens[position].span.end
                position += 1
            }

            skipWord(language.schedule.atWord)
            if let clock = parseClock() {
                return scheduleClause(
                    .weekdays(days, hour: clock.hour, minute: clock.minute),
                    start: startToken.span.start,
                    end: clock.end
                )
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)
        }

        if let (seconds, durationEnd) = parseDurationPhrase(allowBareUnit: true) {
            return scheduleClause(.interval(seconds), start: startToken.span.start, end: durationEnd)
        }
        return scheduleClause(.incomplete, start: startToken.span.start, end: end)
    }

    private mutating func parseClock() -> (hour: Int, minute: Int, end: Int)? {
        guard position < tokens.count,
              case .number(let hourValue) = tokens[position].kind,
              hourValue == hourValue.rounded() else {
            return nil
        }
        var hour = Int(hourValue)
        var end = tokens[position].span.end
        position += 1

        var minute = 0
        if position < tokens.count, case .punctuation(":") = tokens[position].kind {
            position += 1
            guard position < tokens.count,
                  case .number(let minuteValue) = tokens[position].kind,
                  minuteValue == minuteValue.rounded() else {
                return nil
            }
            minute = Int(minuteValue)
            end = tokens[position].span.end
            position += 1
        }

        var meridiem: Bool?
        if position < tokens.count, case .word(let word) = tokens[position].kind {
            if language.schedule.meridiemAM.contains(word) {
                meridiem = false
            } else if language.schedule.meridiemPM.contains(word) {
                meridiem = true
            }
            if meridiem != nil {
                end = tokens[position].span.end
                position += 1
            }
        }

        guard (0...59).contains(minute) else { return nil }

        if let isPM = meridiem {
            guard (1...12).contains(hour) else { return nil }
            if isPM, hour < 12 { hour += 12 }
            if !isPM, hour == 12 { hour = 0 }
        } else {
            guard (0...23).contains(hour), hour == 0 || hour >= 13 else { return nil }
        }

        return (hour, minute, end)
    }

    private mutating func parseDurationPhrase(allowBareUnit: Bool) -> (TimeInterval, Int)? {
        guard position < tokens.count else { return nil }

        var value: Double
        var end: Int

        if case .number(let number) = tokens[position].kind {
            value = number
            end = tokens[position].span.end
            position += 1
        } else if allowBareUnit,
                  case .word(let unit) = tokens[position].kind,
                  let multiplier = language.schedule.durationUnits[unit] {
            end = tokens[position].span.end
            position += 1
            return (multiplier, end)
        } else {
            return nil
        }

        guard position < tokens.count,
              case .word(let unit) = tokens[position].kind,
              let multiplier = language.schedule.durationUnits[unit] else {
            return nil
        }
        end = tokens[position].span.end
        position += 1
        return (value * multiplier, end)
    }

    private mutating func skipWord(_ target: String) {
        if position < tokens.count, case .word(let word) = tokens[position].kind, word == target {
            position += 1
        }
    }

    private func scheduleClause(_ schedule: ParsedSchedule, start: Int, end: Int) -> ParsedClause {
        ParsedClause(
            kind: .schedule,
            span: SourceSpan(start: start, end: end),
            parameter: .schedule(schedule),
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
        return clauseStarts.contains(word)
    }

    private func isConnectorWord(_ word: String) -> Bool {
        language.shared.connectorWords.contains(word)
    }

    private func isConnectorToken(_ token: CommandToken) -> Bool {
        switch token.kind {
        case .word(let word):
            return isConnectorWord(word)
        case .punctuation(let punctuation):
            return language.shared.connectorPunctuation.contains(punctuation)
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
