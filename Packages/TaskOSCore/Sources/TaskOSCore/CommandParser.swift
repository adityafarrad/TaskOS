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
                    if next.isLetter || next.isNumber || Self.wordExtras.contains(next) {
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
    static let clauseKeywords: Set<String> = [
        "open", "hide", "quit", "reveal", "wait", "show", "notify", "put",
        "arrange", "maximize", "center", "copy", "every", "once", "in", "when",
    ]
    enum WhenVerb {
        case lifecycle(LifecycleEvent)
        case wake
        case display(DisplayEvent)
        case volume(VolumeEvent)
    }

    static let whenVerbs: [String: WhenVerb] = [
        "opens": .lifecycle(.launched),
        "launches": .lifecycle(.launched),
        "launched": .lifecycle(.launched),
        "quits": .lifecycle(.quit),
        "exits": .lifecycle(.quit),
        "closes": .lifecycle(.quit),
        "wakes": .wake,
        "woke": .wake,
        "connects": .display(.connected),
        "disconnects": .display(.disconnected),
        "mounts": .volume(.mounted),
        "unmounts": .volume(.unmounted),
    ]
    static let displayPhrases: Set<String> = [
        "a display", "the display", "an external display", "the external display",
        "external display", "a monitor", "an external monitor", "the external monitor",
        "external monitor", "a screen", "an external screen", "the external screen",
    ]
    static let volumePhrases: Set<String> = [
        "a drive", "the drive", "an external drive", "the external drive", "external drive",
        "a volume", "the volume", "an external volume", "the external volume", "external volume",
        "a disk", "the disk", "an external disk", "the external disk",
    ]
    static let timeUnits: Set<String> = ["second", "seconds", "sec", "secs", "s"]
    static let weekdayNames: [String: Weekday] = [
        "sunday": .sunday,
        "monday": .monday,
        "tuesday": .tuesday,
        "wednesday": .wednesday,
        "thursday": .thursday,
        "friday": .friday,
        "saturday": .saturday,
    ]
    static let durationUnits: [String: TimeInterval] = [
        "minute": 60, "minutes": 60, "min": 60, "mins": 60,
        "hour": 3600, "hours": 3600, "hr": 3600, "hrs": 3600,
    ]
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
        case .hideApplication, .quitApplication:
            return clause.resourceNames.isEmpty
        case .openFile, .revealInFinder:
            return clause.fileSelectionKind == nil
        case .applicationLifecycle:
            let name = (clause.lifecycleApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return clause.lifecycleEvent == nil || name.isEmpty
        case .wake, .displayConnection, .externalVolume:
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
        case "hide":
            return parseApplicationListClause(kind: .hideApplication)
        case "quit":
            return parseApplicationListClause(kind: .quitApplication)
        case "reveal":
            return parseReveal()
        case "wait":
            return parseWait()
        case "show", "notify":
            return parseNotification()
        case "copy":
            return parseCopy()
        case "put", "arrange":
            return parseArrange()
        case "maximize":
            return parseArrangeWithFixedPreset(.maximize)
        case "center":
            return parseArrangeWithFixedPreset(.center)
        case "every", "once", "in":
            return parseSchedule()
        case "when":
            return parseWhen()
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
        let (names, end) = collectApplicationNames(after: openToken)

        let joined = names.joined(separator: " ").lowercased()
        let kind: FileTarget.Kind?
        switch joined {
        case "the selected file":
            kind = .file
        case "the selected folder":
            kind = .folder
        default:
            kind = nil
        }

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

        switch joined {
        case "the selected item", "the selected file", "the selected folder":
            return ParsedClause(
                kind: .revealInFinder,
                span: SourceSpan(start: keyword.span.start, end: end),
                parameter: .fileSelection(kind: .file),
                detail: nil
            )
        default:
            return ParsedClause(
                kind: .revealInFinder,
                span: SourceSpan(start: keyword.span.start, end: end),
                parameter: .none,
                detail: nil
            )
        }
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
                if Self.connectors.contains(word) {
                    if isClauseStart(tokenAfterCurrent) {
                        flush()
                        return (names, end)
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

    private mutating func parseArrange() -> ParsedClause {
        let startToken = tokens[position]
        position += 1

        var appWords: [String] = []
        var end = startToken.span.end
        var preset: WindowPreset?

        while position < tokens.count {
            let token = tokens[position]
            guard case .word(let word) = token.kind else { break }
            if Self.connectors.contains(word) { break }
            if word == "on" || word == "to" {
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
            guard case .word(let word) = token.kind else { break }
            if Self.connectors.contains(word) || word == "on" || word == "to" { break }
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

        if position < tokens.count, case .word(let article) = tokens[position].kind, article == "the" {
            end = tokens[position].span.end
            position += 1
        }

        guard position < tokens.count, case .word(let side) = tokens[position].kind else {
            return (nil, end)
        }
        end = tokens[position].span.end
        position += 1

        switch side {
        case "left", "right":
            if position < tokens.count, case .word(let noun) = tokens[position].kind, noun == "half" {
                end = tokens[position].span.end
                position += 1
            }
            return (side == "left" ? .leftHalf : .rightHalf, end)

        case "top", "bottom":
            if position < tokens.count, case .word(let horizontal) = tokens[position].kind,
               horizontal == "left" || horizontal == "right" {
                end = tokens[position].span.end
                position += 1
                let preset: WindowPreset
                switch (side, horizontal) {
                case ("top", "left"): preset = .topLeftQuarter
                case ("top", "right"): preset = .topRightQuarter
                case ("bottom", "left"): preset = .bottomLeftQuarter
                default: preset = .bottomRightQuarter
                }
                return (preset, end)
            }
            if position < tokens.count, case .word(let noun) = tokens[position].kind, noun == "half" {
                end = tokens[position].span.end
                position += 1
            }
            return (side == "top" ? .topHalf : .bottomHalf, end)

        default:
            return (nil, end)
        }
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

    private mutating func parseWhen() -> ParsedClause {
        let keyword = tokens[position]
        position += 1
        var end = keyword.span.end
        var words: [String] = []
        var verb: WhenVerb?

        while position < tokens.count {
            let token = tokens[position]
            guard case .word(let word) = token.kind, !Self.connectors.contains(word) else { break }
            if let found = Self.whenVerbs[word] {
                verb = found
                end = token.span.end
                position += 1
                break
            }
            words.append(token.original)
            end = token.span.end
            position += 1
        }

        let name = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = name.lowercased()
        let span = SourceSpan(start: keyword.span.start, end: end)

        switch verb {
        case .wake:
            if lower == "the mac" {
                return ParsedClause(kind: .wake, span: span, parameter: .wake, detail: nil)
            }
        case .display(let event):
            if Self.displayPhrases.contains(lower) {
                return ParsedClause(kind: .displayConnection, span: span, parameter: .display(event), detail: nil)
            }
        case .volume(let event):
            if Self.volumePhrases.contains(lower) {
                return ParsedClause(kind: .externalVolume, span: span, parameter: .volume(event), detail: nil)
            }
        case .lifecycle(let event):
            return ParsedClause(
                kind: .applicationLifecycle,
                span: span,
                parameter: .lifecycle(event: event, applicationName: name),
                detail: nil
            )
        case .none:
            break
        }

        return ParsedClause(
            kind: .applicationLifecycle,
            span: span,
            parameter: .lifecycle(event: nil, applicationName: name),
            detail: nil
        )
    }

    private mutating func parseCopy() -> ParsedClause {
        let startToken = tokens[position]
        position += 1
        var end = startToken.span.end

        if position < tokens.count, case .word(let word) = tokens[position].kind, word == "text" {
            end = tokens[position].span.end
            position += 1
        }

        guard position < tokens.count else {
            return ParsedClause(
                kind: .copyText,
                span: SourceSpan(start: startToken.span.start, end: end),
                parameter: .copyText(""),
                detail: nil
            )
        }

        let literalStart = tokens[position].span.start
        let literalEnd = consumeClauseRemainder()
        let raw = (text.substring(in: SourceSpan(start: literalStart, end: literalEnd)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedClause(
            kind: .copyText,
            span: SourceSpan(start: startToken.span.start, end: literalEnd),
            parameter: .copyText(Self.stripQuotes(raw)),
            detail: nil
        )
    }

    private static func stripQuotes(_ value: String) -> String {
        if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }

    private mutating func parseSchedule() -> ParsedClause {
        let startToken = tokens[position]
        guard case .word(let keyword) = startToken.kind else {
            position += 1
            return ParsedClause(kind: .unrecognized, span: startToken.span, parameter: .none, detail: nil)
        }
        position += 1
        let end = startToken.span.end

        switch keyword {
        case "in":
            if let (seconds, durationEnd) = parseDurationPhrase(allowBareUnit: false) {
                return scheduleClause(.relative(seconds), start: startToken.span.start, end: durationEnd)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)

        case "once":
            skipWord("at")
            if let clock = parseClock() {
                return scheduleClause(.once(hour: clock.hour, minute: clock.minute), start: startToken.span.start, end: clock.end)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)

        default:
            return parseEvery(startToken: startToken)
        }
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

        switch word {
        case "day", "days":
            end = tokens[position].span.end
            position += 1
            skipWord("at")
            if let clock = parseClock() {
                return scheduleClause(.daily(hour: clock.hour, minute: clock.minute), start: startToken.span.start, end: clock.end)
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)

        case "weekday", "weekdays":
            end = tokens[position].span.end
            position += 1
            skipWord("at")
            if let clock = parseClock() {
                return scheduleClause(
                    .weekdays(Weekday.weekdays, hour: clock.hour, minute: clock.minute),
                    start: startToken.span.start,
                    end: clock.end
                )
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)

        case "weekend", "weekends":
            end = tokens[position].span.end
            position += 1
            skipWord("at")
            if let clock = parseClock() {
                return scheduleClause(
                    .weekdays(Weekday.weekend, hour: clock.hour, minute: clock.minute),
                    start: startToken.span.start,
                    end: clock.end
                )
            }
            return scheduleClause(.incomplete, start: startToken.span.start, end: end)

        default:
            if let firstDay = Self.weekdayNames[word] {
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
                          let day = Self.weekdayNames[next] else {
                        position = saved
                        break
                    }
                    days.insert(day)
                    end = tokens[position].span.end
                    position += 1
                }

                skipWord("at")
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
            switch word {
            case "am", "a.m", "a.m.":
                meridiem = false
            case "pm", "p.m", "p.m.":
                meridiem = true
            default:
                break
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
                  let multiplier = Self.durationUnits[unit] {
            end = tokens[position].span.end
            position += 1
            return (multiplier, end)
        } else {
            return nil
        }

        guard position < tokens.count,
              case .word(let unit) = tokens[position].kind,
              let multiplier = Self.durationUnits[unit] else {
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
