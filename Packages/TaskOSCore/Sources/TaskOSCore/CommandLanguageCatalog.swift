import Foundation

public struct CanonicalTemplate: Hashable, Sendable {
    public let format: String

    public init(_ format: String) {
        self.format = format
    }

    public func render(_ values: [String: String] = [:]) -> String {
        var result = format
        for (slot, value) in values {
            result = result.replacingOccurrences(of: "{\(slot)}", with: value)
        }
        return result
    }
}

public enum CommandClauseRoute: Hashable, Sendable {
    case open
    case hideApplication
    case quitApplication
    case reveal
    case wait
    case notification
    case copy
    case arrange
    case maximize
    case center
    case schedule
    case when
}

public struct CommandLanguageCatalog: Sendable {
    public static let currentRevision = 1

    public struct CanonicalWording: Hashable, Sendable {
        public let standard: CanonicalTemplate
        public let variants: [String: CanonicalTemplate]

        public init(_ standard: String, variants: [String: String] = [:]) {
            self.standard = CanonicalTemplate(standard)
            self.variants = variants.mapValues(CanonicalTemplate.init)
        }

        public func template(_ variant: String? = nil) -> CanonicalTemplate {
            if let variant, let found = variants[variant] {
                return found
            }
            return standard
        }
    }

    public struct CompletionStarter: Hashable, Sendable {
        public let id: String
        public let phrase: String
        public let title: String
        public let category: Suggestion.Category
        public let requiresParameter: Bool

        public init(
            id: String,
            phrase: String,
            title: String,
            category: Suggestion.Category,
            requiresParameter: Bool
        ) {
            self.id = id
            self.phrase = phrase
            self.title = title
            self.category = category
            self.requiresParameter = requiresParameter
        }
    }

    public struct ActionLanguage: Hashable, Sendable {
        public let id: ActionID
        public let headWords: [String]
        public let canonical: CanonicalWording
        public let examples: [String]
        public let guideExample: String
        public let starter: CompletionStarter?
    }

    public struct TriggerLanguage: Hashable, Sendable {
        public let id: TriggerID
        public let headWords: [String]
        public let canonical: CanonicalWording
        public let examples: [String]
        public let guideExample: String
        public let starter: CompletionStarter?
        public let usesImplicitGrammar: Bool
    }

    public struct SharedVocabulary: Hashable, Sendable {
        public let connectorWords: Set<String>
        public let listSeparatorWords: Set<String>
        public let clauseConnectorPhrases: [[String]]
        public let connectorPunctuation: Set<String>
        public let negationWords: Set<String>
        public let actionJoiner: String
    }

    public struct FileVocabulary: Hashable, Sendable {
        public let selectionPhrases: [String: FileTarget.Kind]
        public let revealPhrases: Set<String>
    }

    public struct NotificationVocabulary: Hashable, Sendable {
        public let directWords: Set<String>
        public let articles: Set<String>
        public let nouns: Set<String>
    }

    public struct WaitVocabulary: Hashable, Sendable {
        public let optionalWords: Set<String>
        public let timeUnits: Set<String>
    }

    public struct CopyVocabulary: Hashable, Sendable {
        public let optionalWords: Set<String>
    }

    public struct ArrangeVocabulary: Hashable, Sendable {
        public let joiners: Set<String>
        public let articles: Set<String>
        public let sides: Set<String>
        public let horizontalSides: Set<String>
        public let halfNouns: Set<String>
        public let quarterNouns: Set<String>
        public let leftWord: String
        public let rightWord: String
        public let topWord: String
        public let bottomWord: String
        public let presetPhrases: [WindowPreset: String]
    }

    public struct ScheduleVocabulary: Hashable, Sendable {
        public let headWords: Set<String>
        public let everyWord: String
        public let everydayWord: String
        public let onceWord: String
        public let inWord: String
        public let atWord: String
        public let onWord: String
        public let todayWord: String
        public let tomorrowWord: String
        public let dayWords: Set<String>
        public let weekdayWords: Set<String>
        public let weekendWords: Set<String>
        public let weekdayNames: [String: Weekday]
        public let durationUnits: [String: TimeInterval]
        public let timeUnits: Set<String>
        public let meridiemAM: Set<String>
        public let meridiemPM: Set<String>
        public let optionalSubjectWords: Set<String>
    }

    public struct TriggerVocabulary: Hashable, Sendable {
        public let headWords: Set<String>
        public let wakePhrases: Set<String>
        public let lifecycleVerbs: [String: LifecycleEvent]
        public let displaySubjects: [String]
        public let displayConnectWords: Set<String>
        public let displayDisconnectWords: Set<String>
        public let volumeSubjects: [String]
        public let volumeMountWords: Set<String>
        public let volumeUnmountWords: Set<String>
        public let powerSubjects: [String]
        public let powerToBatterySuffixes: [String]
        public let powerToExternalSuffixes: [String]
        public let batterySubjects: [String]
        public let batteryBelowWords: [String]
        public let batteryAboveWords: [String]
        public let batteryDirectionWords: [ThresholdComparison: String]
    }

    public struct ConversationalVocabulary: Hashable, Sendable {
        public let leadingFrames: [String]
        public let fillerWords: [String]
        public let rationaleMarker: String
        public let rationaleEndings: [String]
        public let finalPunctuation: Set<Character>
    }

    public let actions: [ActionID: ActionLanguage]
    public let triggers: [TriggerID: TriggerLanguage]
    public let clauseRoutes: [String: CommandClauseRoute]
    public let shared: SharedVocabulary
    public let file: FileVocabulary
    public let notification: NotificationVocabulary
    public let wait: WaitVocabulary
    public let copy: CopyVocabulary
    public let arrange: ArrangeVocabulary
    public let schedule: ScheduleVocabulary
    public let trigger: TriggerVocabulary
    public let conversational: ConversationalVocabulary
    public let excluded: [String: String]
    public let waitStarters: [CompletionStarter]
    public let notificationStarter: CompletionStarter

    public var parameterStarters: [CompletionStarter] {
        waitStarters + [notificationStarter]
    }

    public func actionLanguage(_ id: ActionID) -> ActionLanguage? {
        actions[id]
    }

    public func triggerLanguage(_ id: TriggerID) -> TriggerLanguage? {
        triggers[id]
    }

    public func actionStarter(_ id: ActionID) -> CompletionStarter? {
        actions[id]?.starter
    }

    public func whenStarters() -> [CompletionStarter] {
        TriggerID.allCases.compactMap { triggers[$0]?.starter }
    }

    public func clauseStartWords() -> Set<String> {
        Set(clauseRoutes.keys).union(excluded.keys).union(shared.negationWords)
    }

    public func canonicalActionTemplate(_ id: ActionID, variant: String? = nil) -> CanonicalTemplate? {
        actions[id]?.canonical.template(variant)
    }

    public func guideExample(for id: ActionID) -> String? {
        actions[id]?.guideExample
    }

    public func guideExample(for id: TriggerID) -> String? {
        triggers[id]?.guideExample
    }

    public func canonicalTriggerTemplate(_ id: TriggerID, variant: String? = nil) -> CanonicalTemplate? {
        triggers[id]?.canonical.template(variant)
    }

    public func scheduleTemplate(_ variant: String) -> CanonicalTemplate? {
        triggers[.schedule]?.canonical.variants[variant]
    }

    public func arrangePresetPhrase(_ preset: WindowPreset) -> String {
        arrange.presetPhrases[preset] ?? preset.displayName
    }

    public func applicationPhrase(_ name: String) -> String {
        let needsQuotes = name.isEmpty
            || name.contains("\"")
            || name.contains("\\")
            || name.contains(",")
            || name.contains(where: { $0.isWhitespace })
            || reservedApplicationWords.contains(name.lowercased())
        guard needsQuotes else { return name }

        let escaped = name
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private var reservedApplicationWords: Set<String> {
        var words = shared.connectorWords
        words.formUnion(shared.negationWords)
        words.formUnion(clauseRoutes.keys)
        words.formUnion(excluded.keys)
        words.insert(conversational.rationaleMarker)
        words.formUnion(conversational.fillerWords)
        return words
    }

    public func copyTextPhrase(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return canonicalActionTemplate(.copyText)?.render(["text": escaped]) ?? "Copy \"\(escaped)\""
    }

    public func isRationaleMarker(_ word: String) -> Bool {
        word == conversational.rationaleMarker
    }

    public func isFinalPunctuation(_ character: Character) -> Bool {
        conversational.finalPunctuation.contains(character)
    }

    public func leadingFrameEnd(in text: String) -> Int? {
        let phrases = (conversational.leadingFrames + conversational.fillerWords)
            .sorted { $0.count > $1.count }
        var offset = 0
        var matched = false

        while true {
            let before = offset
            offset = Self.skipWhitespace(text, from: offset)

            var matchedRound = false
            for phrase in phrases {
                guard let end = Self.matchPhrase(text, at: offset, phrase: phrase) else { continue }
                offset = Self.skipWhitespace(text, from: end)
                if Self.character(text, at: offset) == "," {
                    offset = Self.skipWhitespace(text, from: offset + 1)
                }
                matched = true
                matchedRound = true
                break
            }

            if !matchedRound {
                offset = before
                break
            }
        }

        return matched ? offset : nil
    }

    public func rationaleSpan(in text: String) -> SourceSpan? {
        let tokens = CommandTokenizer.tokenize(text)
        var index = 0

        while index < tokens.count {
            let token = tokens[index]

            if case .punctuation(let punctuation) = token.kind, punctuation == "\"" {
                guard case .success(let literal) = CommandLiteralScanner.scan(text, at: token.span.start) else {
                    return nil
                }
                while index < tokens.count, tokens[index].span.start < literal.span.end {
                    index += 1
                }
                continue
            }

            if case .word(let word) = token.kind, isRationaleMarker(word) {
                let raw = text.substring(in: SourceSpan(start: token.span.start, end: text.utf16.count)) ?? ""
                var normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if let last = normalized.last, conversational.finalPunctuation.contains(last) {
                    normalized = String(normalized.dropLast())
                }
                normalized = normalized
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()

                guard conversational.rationaleEndings.contains(normalized) else {
                    return nil
                }
                return SourceSpan(start: token.span.start, end: text.utf16.count)
            }

            index += 1
        }

        return nil
    }

    public func rationaleText(in text: String) -> String? {
        guard let span = rationaleSpan(in: text) else { return nil }
        return text.substring(in: span)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func skipWhitespace(_ text: String, from offset: Int) -> Int {
        var result = offset
        while let character = character(text, at: result), character.isWhitespace {
            result += String(character).utf16.count
        }
        return result
    }

    private static func matchPhrase(_ text: String, at offset: Int, phrase: String) -> Int? {
        guard let range = SourceSpan(start: offset, end: text.utf16.count).range(in: text) else {
            return nil
        }
        var index = range.lowerBound
        for phraseCharacter in phrase {
            guard index < text.endIndex else { return nil }
            let character = text[index]
            guard String(character).lowercased() == String(phraseCharacter) else { return nil }
            index = text.index(after: index)
        }
        if index < text.endIndex {
            let next = text[index]
            guard next.isWhitespace || next == "," else { return nil }
        }
        return text.utf16.distance(from: text.startIndex, to: index)
    }

    private static func character(_ text: String, at offset: Int) -> Character? {
        guard let range = SourceSpan(start: offset, end: offset + 1).range(in: text) else {
            return nil
        }
        return text[range].first
    }

    public func websitePhrase(url: String) -> String {
        canonicalActionTemplate(.openWebsite)?.render(["url": url]) ?? "Open \(url)"
    }

    public func clockText(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        var display = hour % 12
        if display == 0 { display = 12 }
        return String(format: "%d:%02d %@", display, minute, period)
    }

    public func intervalText(_ seconds: TimeInterval) -> String {
        let normalized = (seconds * 1000).rounded() / 1000
        if normalized >= 3600, normalized.truncatingRemainder(dividingBy: 3600) == 0 {
            let hours = Int(normalized / 3600)
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        if normalized >= 60, normalized.truncatingRemainder(dividingBy: 60) == 0 {
            let minutes = Int(normalized / 60)
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }
        let value = Self.numberText(normalized)
        return normalized == 1 ? "\(value) second" : "\(value) seconds"
    }

    private static func numberText(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        var text = String(format: "%.3f", value)
        while text.hasSuffix("0") {
            text.removeLast()
        }
        if text.hasSuffix(".") {
            text.removeLast()
        }
        return text
    }

    public func absoluteDateTimeText(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d-%02d-%02d at %02d:%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }
}

extension CommandLanguageCatalog {
    public static let standard = CommandLanguageCatalog(
        actions: standardActions,
        triggers: standardTriggers,
        clauseRoutes: [
            "open": .open,
            "launch": .open,
            "start": .open,
            "hide": .hideApplication,
            "quit": .quitApplication,
            "reveal": .reveal,
            "wait": .wait,
            "show": .notification,
            "notify": .notification,
            "copy": .copy,
            "put": .arrange,
            "arrange": .arrange,
            "maximize": .maximize,
            "center": .center,
            "every": .schedule,
            "everyday": .schedule,
            "once": .schedule,
            "in": .schedule,
            "at": .schedule,
            "today": .schedule,
            "tomorrow": .schedule,
            "when": .when,
        ],
        shared: SharedVocabulary(
            connectorWords: ["and", "then", "also", "next", "after", "that", "followed", "by"],
            listSeparatorWords: ["and", "then", "also"],
            clauseConnectorPhrases: [["next"], ["after", "that"], ["followed", "by"]],
            connectorPunctuation: [",", ";"],
            negationWords: ["not", "never", "without", "don", "dont"],
            actionJoiner: ", then "
        ),
        file: FileVocabulary(
            selectionPhrases: [
                "the selected file": .file,
                "the selected folder": .folder,
            ],
            revealPhrases: ["the selected item", "the selected file", "the selected folder"]
        ),
        notification: NotificationVocabulary(
            directWords: ["notify"],
            articles: ["a", "the"],
            nouns: ["notification"]
        ),
        wait: WaitVocabulary(
            optionalWords: ["for"],
            timeUnits: ["second", "seconds", "sec", "secs", "s"]
        ),
        copy: CopyVocabulary(
            optionalWords: ["text"]
        ),
        arrange: ArrangeVocabulary(
            joiners: ["on", "to"],
            articles: ["the"],
            sides: ["left", "right", "top", "bottom"],
            horizontalSides: ["left", "right"],
            halfNouns: ["half"],
            quarterNouns: ["quarter", "quarters"],
            leftWord: "left",
            rightWord: "right",
            topWord: "top",
            bottomWord: "bottom",
            presetPhrases: [
                .leftHalf: "on the left half",
                .rightHalf: "on the right half",
                .topHalf: "on the top half",
                .bottomHalf: "on the bottom half",
                .topLeftQuarter: "on the top-left quarter",
                .topRightQuarter: "on the top-right quarter",
                .bottomLeftQuarter: "on the bottom-left quarter",
                .bottomRightQuarter: "on the bottom-right quarter",
                .maximize: "maximized",
                .center: "centered",
            ]
        ),
        schedule: ScheduleVocabulary(
            headWords: ["every", "everyday", "once", "in", "at", "today", "tomorrow"],
            everyWord: "every",
            everydayWord: "everyday",
            onceWord: "once",
            inWord: "in",
            atWord: "at",
            onWord: "on",
            todayWord: "today",
            tomorrowWord: "tomorrow",
            dayWords: ["day", "days"],
            weekdayWords: ["weekday", "weekdays"],
            weekendWords: ["weekend", "weekends"],
            weekdayNames: [
                "sunday": .sunday,
                "monday": .monday,
                "tuesday": .tuesday,
                "wednesday": .wednesday,
                "thursday": .thursday,
                "friday": .friday,
                "saturday": .saturday,
            ],
            durationUnits: [
                "second": 1, "seconds": 1, "sec": 1, "secs": 1, "s": 1,
                "minute": 60, "minutes": 60, "min": 60, "mins": 60,
                "hour": 3600, "hours": 3600, "hr": 3600, "hrs": 3600,
            ],
            timeUnits: ["second", "seconds", "sec", "secs", "s"],
            meridiemAM: ["am", "a.m", "a.m."],
            meridiemPM: ["pm", "p.m", "p.m."],
            optionalSubjectWords: ["you"]
        ),
        trigger: TriggerVocabulary(
            headWords: ["when"],
            wakePhrases: ["the mac wakes", "the mac woke", "my mac wakes"],
            lifecycleVerbs: [
                "opens": .launched,
                "launches": .launched,
                "launched": .launched,
                "quits": .quit,
                "exits": .quit,
            ],
            displaySubjects: [
                "a display", "the display", "an external display", "the external display",
                "external display", "a monitor", "an external monitor", "the external monitor",
                "external monitor", "a screen", "an external screen", "the external screen",
            ],
            displayConnectWords: ["connects"],
            displayDisconnectWords: ["disconnects"],
            volumeSubjects: [
                "a drive", "the drive", "an external drive", "the external drive", "external drive",
                "a volume", "the volume", "an external volume", "the external volume", "external volume",
                "a disk", "the disk", "an external disk", "the external disk",
            ],
            volumeMountWords: ["mounts"],
            volumeUnmountWords: ["unmounts"],
            powerSubjects: ["the mac", "my mac", "this mac", "i"],
            powerToBatterySuffixes: [
                "switches to battery",
                "switch to battery",
                "switches to battery power",
                "switch to battery power",
                "is on battery",
            ],
            powerToExternalSuffixes: [
                "switches to power",
                "switch to power",
                "switches to external power",
                "switch to external power",
                "connects to power",
                "connect to power",
                "connects to external power",
                "connect to external power",
            ],
            batterySubjects: ["the battery", "my battery", "battery"],
            batteryBelowWords: ["drops below", "falls below", "goes below", "drops to", "falls to"],
            batteryAboveWords: ["rises above", "goes above", "rises to", "reaches"],
            batteryDirectionWords: [.below: "drops below", .above: "rises above"]
        ),
        conversational: ConversationalVocabulary(
            leadingFrames: [
                "hey taskos",
                "taskos",
                "please",
                "can you",
                "could you",
                "would you",
                "i would like you to",
                "i'd like you to",
                "i’d like you to",
                "make sure",
            ],
            fillerWords: ["um", "uh"],
            rationaleMarker: "so",
            rationaleEndings: [
                "so i can journal my day",
                "so that i can journal my day",
                "so i can journal my day as i keep forgetting",
                "so that i can journal my day as i keep forgetting",
            ],
            finalPunctuation: [".", "?", "!"]
        ),
        excluded: [
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
        ],
        waitStarters: [
            CompletionStarter(
                id: "param.wait.1",
                phrase: "Wait 1 second",
                title: "Wait 1 second",
                category: .parameter,
                requiresParameter: false
            ),
            CompletionStarter(
                id: "param.wait.5",
                phrase: "Wait 5 seconds",
                title: "Wait 5 seconds",
                category: .parameter,
                requiresParameter: false
            ),
            CompletionStarter(
                id: "param.wait.30",
                phrase: "Wait 30 seconds",
                title: "Wait 30 seconds",
                category: .parameter,
                requiresParameter: false
            ),
        ],
        notificationStarter: CompletionStarter(
            id: "param.notification",
            phrase: "Show a notification",
            title: "Show a notification",
            category: .parameter,
            requiresParameter: false
        )
    )

    private static let standardActions: [ActionID: ActionLanguage] = [
        .openApplication: ActionLanguage(
            id: .openApplication,
            headWords: ["open", "launch", "start"],
            canonical: CanonicalWording("Open {application}"),
            examples: ["Open Notes"],
            guideExample: "Open Safari",
            starter: CompletionStarter(
                id: "action.openApplication",
                phrase: "Open an application",
                title: "Open an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .hideApplication: ActionLanguage(
            id: .hideApplication,
            headWords: ["hide"],
            canonical: CanonicalWording("Hide {application}"),
            examples: ["Hide Safari"],
            guideExample: "Hide Mail",
            starter: CompletionStarter(
                id: "action.hideApplication",
                phrase: "Hide Safari",
                title: "Hide an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .quitApplication: ActionLanguage(
            id: .quitApplication,
            headWords: ["quit"],
            canonical: CanonicalWording("Quit {application}"),
            examples: ["Quit Safari"],
            guideExample: "Quit Safari",
            starter: CompletionStarter(
                id: "action.quitApplication",
                phrase: "Quit Safari",
                title: "Quit an application",
                category: .action,
                requiresParameter: true
            )
        ),
        .openFile: ActionLanguage(
            id: .openFile,
            headWords: ["open"],
            canonical: CanonicalWording(
                "Open the selected file",
                variants: ["folder": "Open the selected folder"]
            ),
            examples: ["Open the selected file", "Open the selected folder"],
            guideExample: "Open the selected file",
            starter: CompletionStarter(
                id: "action.openFile",
                phrase: "Open the selected file",
                title: "Open a file or folder",
                category: .action,
                requiresParameter: true
            )
        ),
        .revealInFinder: ActionLanguage(
            id: .revealInFinder,
            headWords: ["reveal"],
            canonical: CanonicalWording("Reveal the selected item"),
            examples: ["Reveal the selected item"],
            guideExample: "Reveal the selected item",
            starter: CompletionStarter(
                id: "action.revealInFinder",
                phrase: "Reveal the selected item",
                title: "Reveal in Finder",
                category: .action,
                requiresParameter: true
            )
        ),
        .openWebsite: ActionLanguage(
            id: .openWebsite,
            headWords: ["open"],
            canonical: CanonicalWording("Open {url}"),
            examples: ["Open https://example.com"],
            guideExample: "Open https://example.com",
            starter: CompletionStarter(
                id: "action.openWebsite",
                phrase: "Open https://",
                title: "Open a website",
                category: .action,
                requiresParameter: true
            )
        ),
        .arrangeWindow: ActionLanguage(
            id: .arrangeWindow,
            headWords: ["put", "arrange", "maximize", "center"],
            canonical: CanonicalWording(
                "Put {application} {preset}",
                variants: [
                    "maximize": "Maximize {application}",
                    "center": "Center {application}",
                ]
            ),
            examples: ["Put Safari on the left half", "Maximize Safari", "Center Safari"],
            guideExample: "Put Safari on the left half",
            starter: CompletionStarter(
                id: "action.arrangeWindow",
                phrase: "Put an application on the left half",
                title: "Arrange a window",
                category: .action,
                requiresParameter: true
            )
        ),
        .wait: ActionLanguage(
            id: .wait,
            headWords: ["wait"],
            canonical: CanonicalWording("Wait {duration} seconds"),
            examples: ["Wait 5 seconds"],
            guideExample: "Wait 5 seconds",
            starter: CompletionStarter(
                id: "action.wait",
                phrase: "Wait 5 seconds",
                title: "Wait",
                category: .action,
                requiresParameter: true
            )
        ),
        .showNotification: ActionLanguage(
            id: .showNotification,
            headWords: ["show", "notify"],
            canonical: CanonicalWording("Show a notification"),
            examples: ["Show a notification", "Notify"],
            guideExample: "Show a notification",
            starter: CompletionStarter(
                id: "action.showNotification",
                phrase: "Show a notification",
                title: "Show a notification",
                category: .action,
                requiresParameter: false
            )
        ),
        .copyText: ActionLanguage(
            id: .copyText,
            headWords: ["copy"],
            canonical: CanonicalWording("Copy \"{text}\""),
            examples: ["Copy \"meeting agenda\""],
            guideExample: "Copy \"meeting agenda\"",
            starter: CompletionStarter(
                id: "action.copyText",
                phrase: "Copy \"text\"",
                title: "Copy text",
                category: .action,
                requiresParameter: true
            )
        ),
    ]

    private static let standardTriggers: [TriggerID: TriggerLanguage] = [
        .manual: TriggerLanguage(
            id: .manual,
            headWords: [],
            canonical: CanonicalWording("Manually"),
            examples: [],
            guideExample: "Manually open Safari and Notes",
            starter: nil,
            usesImplicitGrammar: true
        ),
        .schedule: TriggerLanguage(
            id: .schedule,
            headWords: ["every", "everyday", "once", "in", "at", "today", "tomorrow"],
            canonical: CanonicalWording(
                "Every day at {clock}",
                variants: [
                    "oneTime": "Once on {date}",
                    "daily": "Every day at {clock}",
                    "weekdays": "Every {days} at {clock}",
                    "interval": "Every {interval}",
                    "relative": "In {interval}",
                    "once": "Once at {clock}",
                    "today": "Today at {clock}",
                    "tomorrow": "Tomorrow at {clock}",
                ]
            ),
            examples: [
                "Every day at 09:00",
                "Every weekday at 09:00",
                "Every 30 minutes",
                "In 45 minutes",
                "Once at 19:00",
                "Once on 2026-09-20 at 09:00",
            ],
            guideExample: "Every weekday at 9 am open Safari",
            starter: nil,
            usesImplicitGrammar: false
        ),
        .applicationLifecycle: TriggerLanguage(
            id: .applicationLifecycle,
            headWords: ["when"],
            canonical: CanonicalWording("When {application} {event}"),
            examples: ["When Safari opens", "When Safari quits"],
            guideExample: "When Safari opens, show a notification",
            starter: CompletionStarter(
                id: "trigger.appLifecycle",
                phrase: "When Safari opens",
                title: "When an app opens or quits",
                category: .trigger,
                requiresParameter: true
            ),
            usesImplicitGrammar: false
        ),
        .wake: TriggerLanguage(
            id: .wake,
            headWords: ["when"],
            canonical: CanonicalWording("When the Mac wakes"),
            examples: ["When the Mac wakes"],
            guideExample: "When the Mac wakes, show a notification",
            starter: CompletionStarter(
                id: "trigger.wake",
                phrase: "When the Mac wakes",
                title: "When the Mac wakes",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .displayConnection: TriggerLanguage(
            id: .displayConnection,
            headWords: ["when"],
            canonical: CanonicalWording(
                "When {display} connects",
                variants: ["disconnected": "When {display} disconnects"]
            ),
            examples: ["When a display connects", "When an external display disconnects"],
            guideExample: "When a display connects, arrange Safari on the left half",
            starter: CompletionStarter(
                id: "trigger.display",
                phrase: "When a display connects",
                title: "When a display connects or disconnects",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .externalVolume: TriggerLanguage(
            id: .externalVolume,
            headWords: ["when"],
            canonical: CanonicalWording(
                "When {volume} mounts",
                variants: ["unmounted": "When {volume} unmounts"]
            ),
            examples: ["When an external drive mounts", "When a drive unmounts"],
            guideExample: "When an external drive mounts, open a folder",
            starter: CompletionStarter(
                id: "trigger.volume",
                phrase: "When an external drive mounts",
                title: "When an external drive mounts or unmounts",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .powerSource: TriggerLanguage(
            id: .powerSource,
            headWords: ["when"],
            canonical: CanonicalWording("When the Mac {event}"),
            examples: ["When the Mac switches to battery", "When I connect to power"],
            guideExample: "When the Mac switches to battery, show a notification",
            starter: CompletionStarter(
                id: "trigger.power",
                phrase: "When the Mac switches to battery",
                title: "When the power source changes",
                category: .trigger,
                requiresParameter: false
            ),
            usesImplicitGrammar: false
        ),
        .batteryThreshold: TriggerLanguage(
            id: .batteryThreshold,
            headWords: ["when"],
            canonical: CanonicalWording("When the battery {direction} {percentage}%"),
            examples: ["When the battery drops below 20%", "When the battery rises above 80%"],
            guideExample: "When the battery drops below 20%, show a notification",
            starter: CompletionStarter(
                id: "trigger.battery",
                phrase: "When the battery drops below 20%",
                title: "When the battery crosses a percentage",
                category: .trigger,
                requiresParameter: true
            ),
            usesImplicitGrammar: false
        ),
    ]
}
