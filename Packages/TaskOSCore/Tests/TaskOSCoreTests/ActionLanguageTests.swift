import Testing
import Foundation
@testable import TaskOSCore

@Suite("Action language")
struct ActionLanguageTests {
    private let parser = CommandParser()

    @Test func approvedActionAliasesParseToTheirCapability() {
        let samples: [(String, ParsedClauseKind)] = [
            ("open Notes", .openApplication),
            ("launch Notes", .openApplication),
            ("start Notes", .openApplication),
            ("hide Notes", .hideApplication),
            ("quit Notes", .quitApplication),
            ("reveal the selected item", .revealInFinder),
            ("open the selected file", .openFile),
            ("open the selected folder", .openFile),
            ("put Notes on the left half", .arrangeWindow),
            ("maximize Notes", .arrangeWindow),
            ("center Notes", .arrangeWindow),
            ("wait 2 seconds", .wait),
            ("show a notification", .showNotification),
            ("notify", .showNotification),
            ("copy \"text\"", .copyText),
            ("open https://example.com", .openApplication),
        ]

        for (command, kind) in samples {
            #expect(parser.parse(command).clauses.contains { $0.kind == kind }, "\(command)")
        }
    }

    @Test func quotedApplicationNamesContainConnectors() {
        let parsed = parser.parse("Open \"Research and Notes\", then open Safari")
        let names = parsed.clauses
            .filter { $0.kind == .openApplication }
            .flatMap(\.resourceNames)
        #expect(names == ["Research and Notes", "Safari"])
        #expect(parsed.outcome == .complete)
        #expect(parsed.coverage.isComplete)
    }

    @Test func multiWordNameCanonicalPhraseReparses() {
        let action = ActionConfiguration.openApplication(
            OpenApplicationAction(
                application: .application(bundleIdentifier: "com.google.Chrome", label: "Google Chrome")
            )
        )
        let phrase = CanonicalPhrase.text(for: action)
        #expect(phrase == "Open \"Google Chrome\"")

        let parsed = parser.parse(phrase)
        #expect(parsed.outcome == .complete)
        let names = parsed.clauses
            .filter { $0.kind == .openApplication }
            .flatMap(\.resourceNames)
        #expect(names == ["Google Chrome"])
    }

    @Test func urlsKeepPathsQueriesAndFragments() {
        let url = "https://example.com/path?q=1&x=2#frag"
        var document = ComposerDocument(text: "open \(url)")

        guard case .openWebsite(let typed, _)? = document.actions.first?.draft else {
            Issue.record("Expected a website draft")
            return
        }
        #expect(typed == url)
        #expect(!document.hasUnresolvedWebsites)
        #expect(document.makeDefinition(name: "Site") != nil)
    }

    @Test func bareDomainSuggestionRequiresExplicitAcceptance() {
        let engine = SuggestionEngine()
        let suggestions = engine.suggestions(for: "open apple.com")
        guard let website = suggestions.first(where: { $0.id.hasPrefix("website.") }) else {
            Issue.record("Expected a website replacement suggestion")
            return
        }
        #expect(website.phrase == "Open https://apple.com")

        var document = ComposerDocument(text: "open apple.com")
        #expect(document.makeDefinition(name: "Site") == nil)

        document.accept(website)
        #expect(document.text == "Open https://apple.com")
        #expect(document.makeDefinition(name: "Site") != nil)
    }

    @Test func unquotedCopyTextNeedsInput() {
        let parsed = parser.parse("copy agenda")
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.clauses.first { $0.kind == .copyText }?.copyText == "")
    }

    @Test func quotedCopyKeepsConnectorsCommasAndSemicolons() {
        let parsed = parser.parse("copy \"a, then b; c\"")
        #expect(parsed.clauses.first { $0.kind == .copyText }?.copyText == "a, then b; c")
        #expect(parsed.outcome == .complete)
    }

    @Test func negatedActionsBlockCompletion() {
        let commands = [
            "do not open Safari",
            "not open Safari",
            "open Safari and not Notes",
            "never quit Notes",
        ]
        for command in commands {
            #expect(parser.parse(command).outcome != .complete, "\(command) should not complete")
        }
    }

    @Test func unsupportedDestructiveTailFailsClosed() {
        let parsed = parser.parse("open Safari and delete Downloads")
        #expect(parsed.outcome == .unsupported)
        #expect(parsed.clauses.contains { $0.kind == .unsupported })
    }

    @Test func missingValuesReportExpectedSlots() {
        #expect(
            parser.parse("open").clauses.first { $0.kind == .openApplication }?.expectedSlots == [.application]
        )
        #expect(
            parser.parse("put Safari").clauses.first { $0.kind == .arrangeWindow }?.expectedSlots == [.preset]
        )
        #expect(
            parser.parse("wait").clauses.first { $0.kind == .wait }?.expectedSlots == [.duration]
        )
        #expect(
            parser.parse("reveal the selected").clauses.first { $0.kind == .revealInFinder }?.expectedSlots == [.file]
        )
        #expect(
            parser.parse("copy").clauses.first { $0.kind == .copyText }?.expectedSlots == [.text]
        )
    }

    @Test func connectorWordAppNamesAreNotDropped() {
        let parsed = parser.parse("open Safari and Next")
        let names = parsed.clauses
            .filter { $0.kind == .openApplication }
            .flatMap(\.resourceNames)
        #expect(names == ["Safari", "Next"])
        #expect(parsed.outcome == .complete)
        #expect(parsed.coverage.isComplete)
    }

    @Test func danglingConnectorsFailClosed() {
        for command in ["open Safari and", "open Safari then", "wait 1 second and"] {
            let parsed = parser.parse(command)
            #expect(parsed.outcome != .complete, "\(command)")
            #expect(!parsed.coverage.isComplete, "\(command)")
        }
    }

    @Test func repeatedActionHeadsCreateBoundaries() {
        let parsed = parser.parse("open Notes open Safari")
        let names = parsed.clauses
            .filter { $0.kind == .openApplication }
            .map(\.resourceNames)
        #expect(names == [["Notes"], ["Safari"]])
        #expect(parsed.outcome == .complete)
        #expect(parsed.coverage.isComplete)

        let document = ComposerDocument(text: "open Notes open Safari")
        #expect(document.actions.count == 2)
    }

    @Test func canonicalPhrasesQuoteReservedApplicationNames() {
        for name in ["and", "then", "so", "next", "wait", "open", "hide"] {
            let action = ActionConfiguration.openApplication(
                OpenApplicationAction(
                    application: .application(bundleIdentifier: "com.example.\(name)", label: name)
                )
            )
            let phrase = CanonicalPhrase.text(for: action)
            let parsed = parser.parse(phrase)
            #expect(parsed.outcome == .complete, "\(name): \(phrase)")
            let names = parsed.clauses
                .filter { $0.kind == .openApplication }
                .flatMap(\.resourceNames)
            #expect(names == [name], "\(name): \(phrase)")
        }
    }

    @Test func copyTextLiteralRoundTripsQuotesAndBackslashes() {
        for value in ["he said \"hi\" and \\ bye", "path\\", "plain text"] {
            var document = ComposerDocument()
            document.addAction(.copyText(value))

            let reparsed = ComposerDocument(text: document.text)
            let restored = reparsed.actions.compactMap { action -> String? in
                if case .copyText(let text) = action.draft { return text }
                return nil
            }
            #expect(restored == [value], "\(value) -> \(document.text)")
            #expect(reparsed.makeDefinition(name: "Copy") != nil, "\(value) -> \(document.text)")
        }
    }

    @Test func expandedApplicationListRespectsActionLimit() {
        let twelve = "open " + (1...12).map { "App\($0)" }.joined(separator: " and ")
        let thirteen = "open " + (1...13).map { "App\($0)" }.joined(separator: " and ")

        #expect(parser.parse(twelve).outcome == .complete)

        let parsed = parser.parse(thirteen)
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.message.contains("12") })
    }

    @Test func unclosedQuoteBeforeRationaleBlocks() {
        let command = "open Notes \"so I can journal my day"
        #expect(parser.parse(command).outcome != .complete)

        let document = ComposerDocument(text: command)
        #expect(document.rationaleText == nil)
    }

    @Test func suggestionAcceptanceUsesCheckedUTF16Replacement() {
        var document = ComposerDocument(text: "😀😀 open and No")
        let suggestion = Suggestion(
            id: "app.notes",
            phrase: "Open Notes",
            title: "Notes",
            category: .application,
            requiresParameter: false,
            match: .prefix
        )

        document.accept(suggestion, replacing: document.completionFragmentRange())

        #expect(document.text == "😀😀 open and Open Notes")
    }

    @Test func suggestionAcceptanceRejectsAnInvalidReplacementRange() {
        var document = ComposerDocument(text: "open No")
        let suggestion = Suggestion(
            id: "app.notes",
            phrase: "Open Notes",
            title: "Notes",
            category: .application,
            requiresParameter: false,
            match: .prefix
        )

        document.accept(suggestion, replacing: SourceSpan(start: 900, end: 901))

        #expect(document.text == "Open Notes")
    }
}
