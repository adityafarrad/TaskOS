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
}
