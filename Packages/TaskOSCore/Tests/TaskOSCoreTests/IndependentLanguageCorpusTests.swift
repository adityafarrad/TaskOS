import Testing
import Foundation
@testable import TaskOSCore

@Suite("Independent language corpus")
struct IndependentLanguageCorpusTests {
    private let parser = CommandParser()

    private func expect(_ clause: ParsedClause?, matches expected: CorpusClauseExpectation, index: Int) {
        guard let clause else {
            Issue.record("case \(index): expected a clause")
            return
        }
        #expect(clause.kind == expected.kind, "case \(index)")
        #expect(clause.resourceNames == expected.names, "case \(index)")
        switch expected.parameter {
        case .none:
            break
        case .duration(let value):
            #expect(clause.duration == value, "case \(index)")
        case .copyText(let value):
            #expect(clause.copyText == value, "case \(index)")
        case .preset(let value):
            #expect(clause.arrangePreset == value, "case \(index)")
        case .fileSelection(let kind):
            #expect(clause.fileSelectionKind == kind, "case \(index)")
        }
    }

    @Test func everyActionAliasCorpus() {
        let cases: [(command: String, expectation: CorpusClauseExpectation)] = [
            ("open Safari", .init(kind: .openApplication, names: ["Safari"], parameter: .none)),
            ("launch Safari", .init(kind: .openApplication, names: ["Safari"], parameter: .none)),
            ("start Safari", .init(kind: .openApplication, names: ["Safari"], parameter: .none)),
            ("hide Safari", .init(kind: .hideApplication, names: ["Safari"], parameter: .none)),
            ("quit Safari", .init(kind: .quitApplication, names: ["Safari"], parameter: .none)),
            ("reveal the selected item", .init(kind: .revealInFinder, names: [], parameter: .fileSelection(.file))),
            ("reveal the selected file", .init(kind: .revealInFinder, names: [], parameter: .fileSelection(.file))),
            ("reveal the selected folder", .init(kind: .revealInFinder, names: [], parameter: .fileSelection(.file))),
            ("open the selected file", .init(kind: .openFile, names: [], parameter: .fileSelection(.file))),
            ("open the selected folder", .init(kind: .openFile, names: [], parameter: .fileSelection(.folder))),
            ("put Safari on the left half", .init(kind: .arrangeWindow, names: [], parameter: .preset(.leftHalf))),
            ("arrange Safari on the right half", .init(kind: .arrangeWindow, names: [], parameter: .preset(.rightHalf))),
            ("maximize Safari", .init(kind: .arrangeWindow, names: [], parameter: .preset(.maximize))),
            ("center Safari", .init(kind: .arrangeWindow, names: [], parameter: .preset(.center))),
            ("wait 5 seconds", .init(kind: .wait, names: [], parameter: .duration(5))),
            ("wait for 5 seconds", .init(kind: .wait, names: [], parameter: .duration(5))),
            ("wait 1 sec", .init(kind: .wait, names: [], parameter: .duration(1))),
            ("show a notification", .init(kind: .showNotification, names: [], parameter: .none)),
            ("show the notification", .init(kind: .showNotification, names: [], parameter: .none)),
            ("notify", .init(kind: .showNotification, names: [], parameter: .none)),
            ("copy \"meeting agenda\"", .init(kind: .copyText, names: [], parameter: .copyText("meeting agenda"))),
            ("copy text \"meeting agenda\"", .init(kind: .copyText, names: [], parameter: .copyText("meeting agenda"))),
            ("open https://example.com", .init(kind: .openApplication, names: ["https://example.com"], parameter: .none)),
        ]

        for (index, item) in cases.enumerated() {
            let parsed = parser.parse(item.command)
            #expect(parsed.outcome == .complete, "case \(index)")
            expect(parsed.clauses.first, matches: item.expectation, index: index)
        }
    }

    @Test func everyScheduleFormCorpus() {
        let cases: [(String, ParsedSchedule)] = [
            ("every day at 9 am", .daily(hour: 9, minute: 0)),
            ("every day at 9:30 pm", .daily(hour: 21, minute: 30)),
            ("every day at 21:00", .daily(hour: 21, minute: 0)),
            ("every weekday at 8:15 am", .weekdays(Weekday.weekdays, hour: 8, minute: 15)),
            ("every monday and friday at 9 am", .weekdays([.monday, .friday], hour: 9, minute: 0)),
            ("every tuesday at 9 am", .weekdays([.tuesday], hour: 9, minute: 0)),
            ("every saturday and sunday at 10 am", .weekdays([.saturday, .sunday], hour: 10, minute: 0)),
            ("every weekend at 10 am", .weekdays(Weekday.weekend, hour: 10, minute: 0)),
            ("every 30 minutes", .interval(1800)),
            ("every 2 hours", .interval(7200)),
            ("every 90 seconds", .interval(90)),
            ("in 45 minutes", .relative(2700)),
            ("in 90 seconds", .relative(90)),
            ("once at 7 pm", .once(hour: 19, minute: 0)),
            ("today at 9:00 am", .relativeDate(dayOffset: 0, hour: 9, minute: 0)),
            ("tomorrow at 11:30 pm", .relativeDate(dayOffset: 1, hour: 23, minute: 30)),
            ("once on 2026-09-20 at 09:00", .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)),
            ("once on 2028-02-29 at 09:00", .absolute(year: 2028, month: 2, day: 29, hour: 9, minute: 0)),
        ]

        for (index, item) in cases.enumerated() {
            let parsed = parser.parse(item.0)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.first { $0.kind == .schedule }?.schedule == item.1, "case \(index)")
        }
    }

    @Test func everyTriggerFamilyCorpus() {
        let eventCases: [(String, ParsedClauseKind)] = [
            ("when Safari opens", .applicationLifecycle),
            ("when Safari launches", .applicationLifecycle),
            ("when Safari launched", .applicationLifecycle),
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

        for (index, item) in eventCases.enumerated() {
            let parsed = parser.parse("\(item.0), then open Safari")
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.contains { $0.kind == item.1 }, "case \(index)")
        }
    }

    @Test func everyConnectorCorpus() {
        for (index, connector) in LanguageCorpus.connectors.enumerated() {
            let command = "open Safari \(connector) wait 1 second"
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.map(\.kind) == [.openApplication, .wait], "case \(index)")
            #expect(parsed.coverage.isComplete, "case \(index)")
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
        for (index, command) in frames.enumerated() {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.filter { $0.kind == .openApplication }.flatMap(\.resourceNames) == ["Notes"], "case \(index)")
        }

        let rationales = [
            "so I can journal my day",
            "so that I can journal my day",
            "so I can journal my day as I keep forgetting",
            "so that I can journal my day as I keep forgetting",
        ]
        for (index, ending) in rationales.enumerated() {
            let parsed = parser.parse("open Notes, \(ending)")
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.coverage.isComplete, "case \(index)")
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
        for (index, item) in actionCases.enumerated() {
            let parsed = parser.parse(item.0)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.first?.kind == item.1, "case \(index)")
        }

        for (index, preset) in WindowPreset.allCases.enumerated() {
            let phrase = CanonicalPhrase.text(
                for: ArrangeWindowAction(
                    application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari"),
                    preset: preset
                )
            )
            let parsed = parser.parse(phrase)
            #expect(parsed.outcome == .complete, "preset case \(index)")
            #expect(parsed.clauses.first { $0.kind == .arrangeWindow }?.arrangePreset == preset, "preset case \(index)")
        }

        let scheduleCases: [(String, ParsedSchedule)] = [
            ("Every day at 9:00 AM", .daily(hour: 9, minute: 0)),
            ("Every Monday, Friday at 5:15 PM", .weekdays([.monday, .friday], hour: 17, minute: 15)),
            ("Every 30 minutes", .interval(1800)),
            ("Once on 2026-09-20 at 09:00", .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)),
        ]
        for (index, item) in scheduleCases.enumerated() {
            let parsed = parser.parse(item.0)
            #expect(parsed.outcome == .complete, "schedule case \(index)")
            #expect(parsed.clauses.first { $0.kind == .schedule }?.schedule == item.1, "schedule case \(index)")
        }
    }

    @Test func generatedPositiveCorpusAcceptsExactly() {
        let commands = LanguageCorpus.positiveCommands(count: 2_000)
        #expect(commands.count >= 2_000)

        var failures: [Int] = []
        for (index, item) in commands.enumerated() {
            let parsed = parser.parse(item.text)
            guard parsed.outcome == .complete,
                  parsed.coverage.isComplete,
                  parsed.clauses.count == item.clauses.count else {
                failures.append(index)
                continue
            }
            for (clause, expected) in zip(parsed.clauses, item.clauses) {
                guard Self.clause(clause, matches: expected) else {
                    failures.append(index)
                    break
                }
            }
        }

        #expect(failures.isEmpty, "failing case indices: \(failures.prefix(8))")
    }

    @Test func negativeCorpusFailsClosed() {
        let negatives = LanguageCorpus.negativeCommands()
        #expect(negatives.count >= 100)

        var silentlyComplete: [Int] = []
        for (index, command) in negatives.enumerated() where parser.parse(command).outcome == .complete {
            silentlyComplete.append(index)
        }

        #expect(silentlyComplete.isEmpty, "failing case indices: \(silentlyComplete.prefix(8))")
    }

    @Test func ambiguityCorpusReportsExactClarifications() {
        for (index, fixture) in LanguageCorpus.ambiguityFixtures.enumerated() {
            let parsed = parser.parse(fixture.command)
            #expect(parsed.outcome == .needsInput, "case \(index)")
            #expect(
                parsed.clarifications.map(\.question).contains(fixture.question),
                "case \(index): \(parsed.clarifications.map(\.question))"
            )
        }
    }

    @Test func limitBoundaryCorpus() {
        let atCharacterLimit = "open " + String(repeating: "a", count: CommandLimits.maximumCharacters - 5)
        #expect(atCharacterLimit.count == CommandLimits.maximumCharacters)
        #expect(
            !parser.parse(atCharacterLimit).diagnostics.contains { $0.message.contains("2,000") }
        )

        let overCharacter = parser.parse(atCharacterLimit + "a")
        #expect(overCharacter.outcome == .needsInput)
        #expect(overCharacter.diagnostics.contains { $0.message.contains("2,000") })

        let twelve = Array(repeating: "open Safari", count: CommandLimits.maximumActions)
            .joined(separator: " and ")
        #expect(parser.parse(twelve).outcome == .complete)

        let thirteen = Array(repeating: "open Safari", count: CommandLimits.maximumActions + 1)
            .joined(separator: " and ")
        let overAction = parser.parse(thirteen)
        #expect(overAction.outcome == .needsInput)
        #expect(overAction.diagnostics.contains { $0.message.contains("12") })

        let atTokens = "open " + Array(repeating: "app", count: CommandLimits.maximumTokens - 1)
            .joined(separator: " ")
        #expect(CommandTokenizer.tokenize(atTokens).count == CommandLimits.maximumTokens)

        let overTokens = "open " + Array(repeating: "app", count: CommandLimits.maximumTokens)
            .joined(separator: " ")
        let overTokenResult = parser.parse(overTokens)
        #expect(overTokenResult.outcome == .needsInput)
        #expect(overTokenResult.diagnostics.contains { $0.message.contains("128") })

        let emojiUnit = "👨‍👩‍👧‍👦"
        let emojiCount = (CommandLimits.maximumUTF16Units / emojiUnit.utf16.count) + 1
        let overUTF16 = String(repeating: emojiUnit, count: emojiCount)
        #expect(overUTF16.count <= CommandLimits.maximumCharacters)
        #expect(overUTF16.utf16.count > CommandLimits.maximumUTF16Units)
        let overUTF16Result = parser.parse(overUTF16)
        #expect(overUTF16Result.outcome == .needsInput)
        #expect(overUTF16Result.diagnostics.contains { $0.message.contains("16,384") })

        let suggestions = SuggestionEngine().suggestions(for: "")
        #expect(suggestions.count <= CommandLimits.maximumVisibleSuggestions)
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

        let unfinishedSelection = ComposerDocument(text: "open the selected")
        #expect(unfinishedSelection.hasUnresolvedApplications)
        #expect(unfinishedSelection.makeDefinition(name: "Selection") == nil)

        let shorthandHalf = parser.parse("put Safari on the left")
        #expect(shorthandHalf.outcome == .complete)
        #expect(shorthandHalf.clauses.first { $0.kind == .arrangeWindow }?.arrangePreset == .leftHalf)
    }

    private static func clause(_ clause: ParsedClause, matches expected: CorpusClauseExpectation) -> Bool {
        guard clause.kind == expected.kind, clause.resourceNames == expected.names else {
            return false
        }
        switch expected.parameter {
        case .none:
            return true
        case .duration(let value):
            return clause.duration == value
        case .copyText(let value):
            return clause.copyText == value
        case .preset(let value):
            return clause.arrangePreset == value
        case .fileSelection(let kind):
            return clause.fileSelectionKind == kind
        }
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
