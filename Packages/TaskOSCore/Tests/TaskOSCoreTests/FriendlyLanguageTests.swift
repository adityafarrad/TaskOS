import Testing
import Foundation
@testable import TaskOSCore

@Suite("Friendly frames and rationale")
struct FriendlyLanguageTests {
    private let parser = CommandParser()

    private let journaling = "Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I can journal my day as I keep forgetting?"

    private func actionNames(_ document: ComposerDocument) -> [String] {
        document.actions.compactMap { action in
            switch action.draft {
            case .openApplication(let name, _): return name
            case .hideApplication(let name, _): return name
            case .quitApplication(let name, _): return name
            default: return nil
            }
        }
    }

    @Test func journalingSentenceWorks() {
        let parsed = parser.parse(journaling)
        #expect(parsed.outcome == .complete)
        #expect(parsed.coverage.isComplete)

        let document = ComposerDocument(text: journaling)
        #expect(document.trigger == .daily(hour: 21, minute: 0))
        #expect(actionNames(document) == ["Notes"])
        #expect(document.rationaleText == "so that I can journal my day as I keep forgetting?")
    }

    @Test func everyLeadingFrameIsAccepted() {
        let commands = [
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

        for command in commands {
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(command)")
            let names = parsed.clauses.filter { $0.kind == .openApplication }.flatMap(\.resourceNames)
            #expect(names == ["Notes"], "\(command)")
        }
    }

    @Test func fillerWordsAreAllowedAroundTheFrame() {
        #expect(parser.parse("Hey TaskOS, um, open Notes").outcome == .complete)
        #expect(parser.parse("uh, can you open Notes").outcome == .complete)
    }

    @Test func oneFinalPunctuationIsAllowed() {
        #expect(parser.parse("open Notes?").outcome == .complete)
        #expect(parser.parse("open Notes!").outcome == .complete)
        #expect(parser.parse("please open Notes ?").outcome == .complete)
    }

    @Test func makeSureDoesNotCreateATrigger() {
        let document = ComposerDocument(text: "make sure open Notes")
        #expect(document.trigger == .manual)
    }

    @Test func everyApprovedRationaleEndingIsAccepted() {
        let endings = [
            "so I can journal my day",
            "so that I can journal my day",
            "so I can journal my day as I keep forgetting",
            "so that I can journal my day as I keep forgetting",
        ]

        for ending in endings {
            let command = "open Notes, \(ending)"
            let parsed = parser.parse(command)
            #expect(parsed.outcome == .complete, "\(ending)")
            #expect(parsed.coverage.isComplete, "\(ending)")

            let document = ComposerDocument(text: command)
            #expect(document.rationaleText == ending, "\(ending)")
            #expect(actionNames(document) == ["Notes"], "\(ending)")
        }
    }

    @Test func canonicalFormProducesTheSameTypedDefinition() {
        let friendly = ComposerDocument(text: journaling)
        let canonical = ComposerDocument(text: "Every day at 9:00 PM, then open Notes")

        #expect(friendly.trigger == canonical.trigger)
        #expect(actionNames(friendly) == actionNames(canonical))
        #expect(friendly.rationaleText != nil)
        #expect(canonical.rationaleText == nil)
    }

    @Test func rationaleIsNotWrittenIntoSavedWorkflows() throws {
        var document = ComposerDocument(text: journaling)
        guard let id = document.actions.first?.id else {
            Issue.record("Expected an action")
            return
        }
        document.resolveApplication(
            id: id,
            reference: .application(bundleIdentifier: "com.apple.Notes", label: "Notes")
        )

        guard let definition = document.makeDefinition(name: "Routine") else {
            Issue.record("Expected a definition")
            return
        }

        let data = try AutomationCoding.encode(definition)
        let encoded = String(data: data, encoding: .utf8) ?? ""
        #expect(!encoded.lowercased().contains("journal"))
        #expect(!encoded.lowercased().contains("forgetting"))
    }

    @Test func arbitraryRationaleBlocksCompletion() {
        let commands = [
            "Open Notes so I can write, then erase Downloads.",
            "Open Notes so I can write, except on weekends.",
            "open Notes so I can not focus",
            "open Notes so I can open Notes every day",
            "open Notes so I can focus if it rains",
            "open Notes so I can delete Downloads",
            "open Notes so I can finish my work",
        ]

        for command in commands {
            #expect(parser.parse(command).outcome != .complete, "\(command)")
        }
    }

    @Test func rationaleMarkerInsideCopyTextIsLiteral() {
        let parsed = parser.parse("copy \"so I can journal my day\"")
        #expect(parsed.outcome == .complete)
        #expect(parsed.clauses.first { $0.kind == .copyText }?.copyText == "so I can journal my day")

        let document = ComposerDocument(text: "copy \"so I can journal my day\"")
        #expect(document.rationaleText == nil)
    }
}
