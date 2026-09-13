import Testing
import Foundation
@testable import TaskOSCore

@Suite("Independent language corpus")
struct IndependentLanguageCorpusTests {
    private let parser = CommandParser()

    private struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private struct GeneratedCase {
        let command: String
        let kinds: [ParsedClauseKind]
        let names: [[String]]
    }

    private let plainAppNames = ["Safari", "Notes", "Calculator", "Mail"]
    private let quotedAppNames = ["Google Chrome", "Visual Studio Code", "Research and Notes"]
    private let waitChoices: [(String, String)] = [
        ("1", "second"), ("2", "seconds"), ("5", "seconds"), ("30", "seconds"), ("0.5", "seconds"),
    ]
    private let copyLiterals = ["hello", "meeting agenda", "a, b; c then d"]
    private let urls = ["https://example.com", "http://example.com/path?q=1#frag"]
    private let arrangePresets = [
        "on the left half", "on the right half", "on the top half", "on the bottom half",
        "on the top-left quarter", "on the top-right quarter",
        "on the bottom-left quarter", "on the bottom-right quarter",
    ]
    private let connectors = ["then", "and then", "and", "also", ",", ";", "after that", "next", "followed by"]

    private func randomAction(_ generator: inout SeededGenerator) -> (text: String, kind: ParsedClauseKind, names: [String]) {
        switch Int.random(in: 0..<12, using: &generator) {
        case 0:
            let name = plainAppNames.randomElement(using: &generator)!
            return ("Open \(name)", .openApplication, [name])
        case 1:
            let name = quotedAppNames.randomElement(using: &generator)!
            return ("Open \"\(name)\"", .openApplication, [name])
        case 2:
            let name = plainAppNames.randomElement(using: &generator)!
            return ("Hide \(name)", .hideApplication, [name])
        case 3:
            let name = plainAppNames.randomElement(using: &generator)!
            return ("Quit \(name)", .quitApplication, [name])
        case 4:
            let wait = waitChoices.randomElement(using: &generator)!
            return ("Wait \(wait.0) \(wait.1)", .wait, [])
        case 5:
            return ("Show a notification", .showNotification, [])
        case 6:
            return ("Notify", .showNotification, [])
        case 7:
            let literal = copyLiterals.randomElement(using: &generator)!
            return ("Copy \"\(literal)\"", .copyText, [])
        case 8:
            return ("Reveal the selected item", .revealInFinder, [])
        case 9:
            let command = Bool.random(using: &generator) ? "Open the selected file" : "Open the selected folder"
            return (command, .openFile, [])
        case 10:
            let name = plainAppNames.randomElement(using: &generator)!
            let preset = arrangePresets.randomElement(using: &generator)!
            return ("Put \(name) \(preset)", .arrangeWindow, [])
        default:
            let url = urls.randomElement(using: &generator)!
            return ("Open \(url)", .openApplication, [url])
        }
    }

    private func generatedPositiveCases(count: Int) -> [GeneratedCase] {
        var generator = SeededGenerator(seed: 0x2_7_D1_2026)
        var cases: [GeneratedCase] = []
        while cases.count < count {
            let actionCount = Int.random(in: 1...3, using: &generator)
            var parts: [String] = []
            var kinds: [ParsedClauseKind] = []
            var names: [[String]] = []
            for index in 0..<actionCount {
                if index > 0 {
                    parts.append(connectors[Int.random(in: 0..<connectors.count, using: &generator)])
                }
                let action = randomAction(&generator)
                parts.append(action.text)
                kinds.append(action.kind)
                names.append(action.names)
            }
            cases.append(GeneratedCase(command: parts.joined(separator: " "), kinds: kinds, names: names))
        }
        return cases
    }

    private func negativeFixtures() -> [String] {
        [
            "",
            "frobnicate",
            "open",
            "hide",
            "quit",
            "wait",
            "show",
            "copy",
            "copy agenda",
            "reveal the selected",
            "put Safari",
            "when Safari closes",
            "every day at 9",
            "every day at 09:00",
            "once on 2027-02-29 at 09:00",
            "once on 2026-13-01 at 09:00",
            "once on 2026-09-20 at 25:00",
            "do not open Safari",
            "not open Safari",
            "open Safari and not Notes",
            "never quit Notes",
            "open Safari and email Bob",
            "open Safari and delete Downloads",
            "every day at 9 am, then every 30 minutes, then open Safari",
            "open Safari, then every day at 9 am, then open Notes",
            "when Safari launches and when Safari quits",
            "open Notes so I can write extra text",
            "open Notes so I can open Notes every day",
            "wait 1 second except on weekends",
        ]
    }

    private func generatedNegativeCases() -> [String] {
        let prefixes = ["open Safari", "wait 1 second", "show a notification", "copy \"hello\"", "hide Notes"]
        let tails = [
            " and delete Downloads", " and email Bob", " and send Mail", " and message Bob",
            " and remove Files", " and move Everything", " and rename Docs", " and run Scripts",
            " and execute Code", " and script Stuff", " and shortcut X", " and click Here",
            " and type Text", " and upload File", " and download Item",
            " so I can do whatever I want", " and not open Notes",
        ]
        var cases: [String] = []
        for prefix in prefixes {
            for tail in tails {
                cases.append(prefix + tail)
            }
        }
        return cases
    }

    @Test func everyActionAliasCorpus() {
        let cases: [(String, ParsedClauseKind)] = [
            ("open Safari", .openApplication),
            ("launch Safari", .openApplication),
            ("start Safari", .openApplication),
            ("hide Safari", .hideApplication),
            ("quit Safari", .quitApplication),
            ("reveal the selected item", .revealInFinder),
            ("open the selected file", .openFile),
            ("open the selected folder", .openFile),
            ("put Safari on the left half", .arrangeWindow),
            ("arrange Safari on the right half", .arrangeWindow),
            ("maximize Safari", .arrangeWindow),
            ("center Safari", .arrangeWindow),
            ("wait 5 seconds", .wait),
            ("show a notification", .showNotification),
            ("notify", .showNotification),
            ("copy \"meeting agenda\"", .copyText),
            ("open https://example.com", .openApplication),
        ]

        for (command, kind) in cases {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.contains { $0.kind == kind }, "\(command)")
        }
    }

    @Test func everyScheduleFormCorpus() {
        let cases: [(String, ParsedSchedule)] = [
            ("every day at 9 am", .daily(hour: 9, minute: 0)),
            ("every day at 9:30 pm", .daily(hour: 21, minute: 30)),
            ("every day at 21:00", .daily(hour: 21, minute: 0)),
            ("every weekday at 8:15 am", .weekdays(Weekday.weekdays, hour: 8, minute: 15)),
            ("every monday and friday at 9 am", .weekdays([.monday, .friday], hour: 9, minute: 0)),
            ("every weekend at 10 am", .weekdays(Weekday.weekend, hour: 10, minute: 0)),
            ("every 30 minutes", .interval(1800)),
            ("every 2 hours", .interval(7200)),
            ("every 90 seconds", .interval(90)),
            ("in 45 minutes", .relative(2700)),
            ("in 90 seconds", .relative(90)),
            ("once at 7 pm", .once(hour: 19, minute: 0)),
            ("once on 2026-09-20 at 09:00", .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)),
            ("once on 2028-02-29 at 09:00", .absolute(year: 2028, month: 2, day: 29, hour: 9, minute: 0)),
        ]

        for (command, schedule) in cases {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.first { $0.kind == .schedule }?.schedule == schedule, "\(command)")
        }
    }

    @Test func everyTriggerFamilyCorpus() {
        let eventCases: [(String, ParsedClauseKind)] = [
            ("when Safari opens", .applicationLifecycle),
            ("when Safari launches", .applicationLifecycle),
            ("when Safari quits", .applicationLifecycle),
            ("when Safari exits", .applicationLifecycle),
            ("when the Mac wakes", .wake),
            ("when a display connects", .displayConnection),
            ("when an external display disconnects", .displayConnection),
            ("when an external drive mounts", .externalVolume),
            ("when a drive unmounts", .externalVolume),
            ("when the Mac switches to battery", .powerSource),
            ("when I connect to power", .powerSource),
            ("when the battery drops below 20%", .batteryThreshold),
            ("when the battery rises above 80%", .batteryThreshold),
        ]

        for (command, kind) in eventCases {
            let parsed = parser.parse("\(command), then open Safari")
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.contains { $0.kind == kind }, "\(command)")
        }
    }

    @Test func everyConnectorCorpus() {
        for connector in connectors {
            let command = "open Safari \(connector) wait 1 second"
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.map(\.kind) == [.openApplication, .wait], "\(command)")
            #expect(parsed.coverage.isComplete, "\(command)")
        }
    }

    @Test func quotedLiteralAndUnicodeCorpus() {
        let parsed = parser.parse("Open \"Research and Notes\", then open Safari")
        #expect(parsed.outcome == .complete)
        #expect(
            parsed.clauses.filter { $0.kind == .openApplication }.flatMap(\.resourceNames)
                == ["Research and Notes", "Safari"]
        )

        let copy = parser.parse("copy \"a, then b; c\"")
        #expect(copy.clauses.first { $0.kind == .copyText }?.copyText == "a, then b; c")

        let combining = parser.parse("open Cafe\u{301}")
        #expect(combining.clauses.first { $0.kind == .openApplication }?.resourceNames == ["Cafe\u{301}"])

        let nonLatin = parser.parse("open ノート")
        #expect(nonLatin.clauses.first { $0.kind == .openApplication }?.resourceNames == ["ノート"])

        let emoji = parser.parse("copy \"emoji 😀 text\"")
        #expect(emoji.outcome == .complete)
        #expect(emoji.coverage.isComplete)
    }

    @Test func friendlyFrameAndRationaleCorpus() {
        let frames = [
            "Hey TaskOS, open Notes",
            "TaskOS, open Notes",
            "please open Notes",
            "can you open Notes",
            "could you open Notes",
            "would you open Notes",
            "I would like you to open Notes",
            "I'd like you to open Notes",
            "I’d like you to open Notes",
            "make sure open Notes",
        ]
        for command in frames {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.filter { $0.kind == .openApplication }.flatMap(\.resourceNames) == ["Notes"], "\(command)")
        }

        let rationales = [
            "so I can journal my day",
            "so that I can journal my day",
            "so I can journal my day as I keep forgetting",
            "so that I can journal my day as I keep forgetting",
        ]
        for ending in rationales {
            let command = "open Notes, \(ending)"
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.coverage.isComplete, "\(command)")
        }

        let journaling = "Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I can journal my day as I keep forgetting?"
        let friendly = ComposerDocument(text: journaling)
        let canonical = ComposerDocument(text: "Every day at 9:00 PM, then open Notes")
        #expect(friendly.trigger == canonical.trigger)
        #expect(actionNames(friendly) == actionNames(canonical))
        #expect(friendly.rationaleText != nil)
        #expect(canonical.rationaleText == nil)
    }

    @Test func canonicalPhraseCorpusReparses() {
        let actionCases: [(String, ParsedClauseKind)] = [
            ("Open Safari", .openApplication),
            ("Hide Safari", .hideApplication),
            ("Quit Safari", .quitApplication),
            ("Open https://example.com", .openApplication),
            ("Open the selected file", .openFile),
            ("Open the selected folder", .openFile),
            ("Reveal the selected item", .revealInFinder),
            ("Put Safari on the left half", .arrangeWindow),
            ("Put Safari on the top-left quarter", .arrangeWindow),
            ("Maximize Safari", .arrangeWindow),
            ("Center Safari", .arrangeWindow),
            ("Wait 5 seconds", .wait),
            ("Show a notification", .showNotification),
            ("Copy \"meeting agenda\"", .copyText),
            ("Open \"Google Chrome\"", .openApplication),
        ]
        for (command, kind) in actionCases {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.first?.kind == kind, "\(command)")
        }

        let scheduleCases: [(String, ParsedSchedule)] = [
            ("Every day at 9:00 AM", .daily(hour: 9, minute: 0)),
            ("Every Monday, Friday at 5:15 PM", .weekdays([.monday, .friday], hour: 17, minute: 15)),
            ("Every 30 minutes", .interval(1800)),
            ("Once on 2026-09-20 at 09:00", .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)),
        ]
        for (command, schedule) in scheduleCases {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            #expect(parsed.clauses.first { $0.kind == .schedule }?.schedule == schedule, "\(command)")
        }
    }

    @Test func generatedPositiveCorpusAcceptsExactly() {
        let cases = generatedPositiveCases(count: 2_000)
        #expect(cases.count >= 2_000)

        var failures: [String] = []
        for item in cases {
            let parsed = parser.parse(item.command)
            guard parsed.outcome == .complete, parsed.coverage.isComplete,
                  parsed.clauses.map(\.kind) == item.kinds else {
                failures.append(item.command)
                continue
            }
            for (index, clause) in parsed.clauses.enumerated() where index < item.names.count {
                switch clause.kind {
                case .openApplication, .hideApplication, .quitApplication:
                    if clause.resourceNames != item.names[index] {
                        failures.append(item.command)
                    }
                default:
                    break
                }
            }
        }

        #expect(failures.isEmpty, "\(failures.prefix(5))")
    }

    @Test func negativeCorpusFailsClosed() {
        let negatives = negativeFixtures() + generatedNegativeCases()
        #expect(negatives.count >= 100)

        var silentlyComplete: [String] = []
        for command in negatives {
            if parser.parse(command).outcome == .complete {
                silentlyComplete.append(command)
            }
        }

        #expect(silentlyComplete.isEmpty, "\(silentlyComplete.prefix(5))")
    }

    @Test func ambiguityCorpusReportsNeedsInput() {
        let cases = [
            "every day at 9",
            "every day at 09:00",
            "once on 2026-13-01 at 09:00",
            "once on 2027-02-29 at 09:00",
            "every day at 9 am, then every 30 minutes, then open Safari",
            "open Safari, then every day at 9 am, then open Notes",
            "when Safari launches and when Safari quits",
        ]

        for command in cases {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .needsInput, "\(command)")
            #expect(parsed.diagnostics.contains { $0.severity == .error }, "\(command)")
        }
    }

    @Test func appListAmbiguityCorpusHasExactRewrites() {
        let snapshot = ApplicationSnapshot(
            revision: 1,
            createdAt: Date(timeIntervalSince1970: 0),
            applications: [
                applicationRecord("Research"),
                applicationRecord("Notes"),
                applicationRecord("Research and Notes"),
                applicationRecord("Safari"),
            ]
        )

        guard case .ambiguous(let groupings) = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: snapshot
        ) else {
            Issue.record("Expected app-list ambiguity")
            return
        }

        let rewrites = Set(groupings.flatMap(\.rewrites))
        #expect(rewrites == Set([
            "Open \"Research and Notes\", then open Safari",
            "Open Research, then open Notes, then open Safari",
        ]))
    }

    @Test func missingSlotCorpusReportsExpectedSlots() {
        #expect(parser.parse("open").clauses.first { $0.kind == .openApplication }?.expectedSlots == [.application])
        #expect(parser.parse("put Safari").clauses.first { $0.kind == .arrangeWindow }?.expectedSlots == [.preset])
        #expect(parser.parse("wait").clauses.first { $0.kind == .wait }?.expectedSlots == [.duration])
        #expect(parser.parse("copy").clauses.first { $0.kind == .copyText }?.expectedSlots == [.text])
        #expect(parser.parse("reveal the selected").clauses.first { $0.kind == .revealInFinder }?.expectedSlots == [.file])
    }

    @Test func compatibilityExceptionsCorpus() {
        let domain = ComposerDocument(text: "open apple.com")
        #expect(domain.hasUnresolvedWebsites)
        #expect(domain.makeDefinition(name: "Site") == nil)

        #expect(parser.parse("copy agenda").outcome == .needsInput)
        #expect(parser.parse("when Safari closes").outcome != .complete)

        let tail = ComposerDocument(text: "open Safari and frobnicate")
        #expect(tail.actions.count == 2)
        #expect(tail.hasUnresolvedApplications)
        #expect(tail.makeDefinition(name: "Tail") == nil)
    }

    private func applicationRecord(_ name: String) -> ApplicationRecord {
        ApplicationRecord(
            bundleIdentifier: "com.example.\(name.replacingOccurrences(of: " ", with: ""))",
            displayName: name,
            fileName: name
        )
    }

    private func actionNames(_ document: ComposerDocument) -> [String] {
        document.actions.compactMap { action in
            if case .openApplication(let name, _) = action.draft { return name }
            return nil
        }
    }
}
