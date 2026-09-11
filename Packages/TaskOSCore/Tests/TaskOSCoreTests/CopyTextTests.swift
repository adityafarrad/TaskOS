import Testing
import Foundation
import TaskOSCore

@Suite("Copy text")
struct CopyTextTests {
    private let parser = CommandParser()

    @Test func parsesQuotedText() {
        let parsed = parser.parse("copy \"meeting agenda\"")
        #expect(parsed.outcome == .complete)
        let clause = parsed.clauses.first { $0.kind == .copyText }
        #expect(clause?.copyText == "meeting agenda")
    }

    @Test func parsesCopyTextKeyword() {
        let parsed = parser.parse("copy text \"standup notes\"")
        let clause = parsed.clauses.first { $0.kind == .copyText }
        #expect(clause?.copyText == "standup notes")
    }

    @Test func missingTextNeedsInput() {
        let parsed = parser.parse("copy")
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.severity == .error })
    }

    @Test func canonicalPhraseRoundTrips() {
        let action = ActionConfiguration.copyText(CopyTextAction(text: "hello world"))
        let phrase = CanonicalPhrase.text(for: action)
        #expect(phrase == "Copy \"hello world\"")

        let parsed = parser.parse(phrase)
        let clause = parsed.clauses.first { $0.kind == .copyText }
        #expect(clause?.copyText == "hello world")
    }

    @Test func composerBuildsCopyDefinition() {
        let document = ComposerDocument(text: "copy \"agenda\"")
        #expect(document.actions.count == 1)

        let definition = document.makeDefinition(name: "Clip")
        #expect(definition?.actions.count == 1)
        if case .copyText(let copy)? = definition?.actions.first {
            #expect(copy.text == "agenda")
        } else {
            Issue.record("Expected a copy text action")
        }
    }

    @Test func emptyCopyBlocksCompletion() {
        var document = ComposerDocument(text: "copy \"agenda\"")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected an action")
            return
        }
        document.updateAction(id: id, draft: .copyText(""))
        #expect(document.hasUnresolvedActions)
        #expect(document.makeDefinition(name: "Clip") == nil)
    }

    @Test func validationBounds() {
        #expect(CopyTextAction(text: "hello").validate().isValid)
        #expect(!CopyTextAction(text: "").validate().isValid)
        #expect(!CopyTextAction(text: String(repeating: "a", count: CopyTextAction.maximumLength + 1)).validate().isValid)
    }

    @Test func copyRequiresNoPermissions() {
        #expect(ActionConfiguration.copyText(CopyTextAction(text: "hi")).requiredPermissions.isEmpty)
    }
}
