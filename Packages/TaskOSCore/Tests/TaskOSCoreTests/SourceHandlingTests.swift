import Testing
import Foundation
@testable import TaskOSCore

@Suite("Source handling")
struct SourceHandlingTests {
    private let parser = CommandParser()

    @Test func spansUseCheckedUTF16Offsets() {
        let text = "😀 open Safari"
        let parsed = parser.parse(text)
        let open = parsed.clauses.first { $0.kind == .openApplication }
        #expect(open?.span.start == 3)
        #expect(text.substring(in: open?.span ?? SourceSpan(start: 0, end: 0)) == "open Safari")
    }

    @Test func combiningMarksAndNonLatinNamesSurvive() {
        let combining = "open Cafe\u{301}"
        let combined = parser.parse(combining).clauses.first { $0.kind == .openApplication }
        #expect(combined?.resourceNames == ["Cafe\u{301}"])

        let nonLatin = "open ノート"
        let japanese = parser.parse(nonLatin).clauses.first { $0.kind == .openApplication }
        #expect(japanese?.resourceNames == ["ノート"])
    }

    @Test func apostrophesArePreservedAndEditable() {
        let text = "open O’Brien and don't stop"
        let span = SourceSpan(start: 5, end: text.utf16.count)
        #expect(text.substring(in: span) == "O’Brien and don't stop")

        let edit = CommandEdit(range: SourceSpan(start: 5, end: 12), replacement: "Alice")
        #expect(edit.applied(to: text) == "open Alice and don't stop")
    }

    @Test func commandEditReplacesIntendedUTF16Range() {
        let text = "😀 open Safari"
        let start = "😀 open ".utf16.count
        let edit = CommandEdit(range: SourceSpan(start: start, end: start + 6), replacement: "Notes")
        #expect(edit.applied(to: text) == "😀 open Notes")
    }

    @Test func invalidUTF16BoundariesAreRejected() {
        let text = "😀 open Safari"
        #expect(text.substring(in: SourceSpan(start: 0, end: 1)) == nil)
        #expect(CommandEdit(range: SourceSpan(start: 0, end: 1), replacement: "x").applied(to: text) == nil)

        let stale = CommandEdit(range: SourceSpan(start: 500, end: 501), replacement: "x")
        #expect(!stale.isValid(in: text))
        #expect(stale.applied(to: text) == nil)
    }

    @Test func commandInputClampsInvalidSelection() {
        let input = CommandInput(
            text: "open Safari",
            selection: SourceSpan(start: 5, end: 11),
            sourceGeneration: 3
        )
        #expect(input.selection == SourceSpan(start: 5, end: 11))
        #expect(input.sourceGeneration == 3)
        #expect(input.locale == .english)
        #expect(!input.isOverLimit)

        let clamped = CommandInput(text: "abc", selection: SourceSpan(start: 99, end: 120))
        #expect(clamped.selection == SourceSpan(start: 3, end: 3))
    }

    @Test func literalScannerHandlesEscapesAndQuotedPunctuation() {
        #expect(scan("\"meeting agenda\"") == "meeting agenda")
        #expect(scan("\"a, then b and c\"") == "a, then b and c")
        #expect(scan("\"say \\\"hi\\\"\"") == "say \"hi\"")
        #expect(scan("\"back\\\\slash\"") == "back\\slash")
        #expect(scan("\"\"") == "")
        #expect(scan("\"keep\\nliteral\"") == "keep\\nliteral")
    }

    @Test func literalScannerRejectsUnclosedAndUnquotedText() {
        if case .failure(.unclosedQuote) = CommandLiteralScanner.scan("\"abc", at: 0) {
            // expected
        } else {
            Issue.record("Expected an unclosed quote failure")
        }

        if case .failure(.notQuoted) = CommandLiteralScanner.scan("abc", at: 0) {
            // expected
        } else {
            Issue.record("Expected a not-quoted failure")
        }
    }

    @Test func copyTextResolvesEscapesAndReportsUnclosedQuotes() {
        let escaped = parser.parse("copy \"say \\\"hi\\\"\"")
        #expect(escaped.clauses.first { $0.kind == .copyText }?.copyText == "say \"hi\"")

        let unclosed = parser.parse("copy \"abc")
        #expect(unclosed.outcome == .needsInput)
        #expect(!unclosed.clarifications.isEmpty)

        let empty = parser.parse("copy \"\"")
        #expect(empty.outcome == .needsInput)
    }

    @Test func completeParseHasFullCoverage() {
        let parsed = parser.parse("open Safari and wait 5 seconds")
        #expect(parsed.outcome == .complete)
        #expect(parsed.coverage.isComplete)
    }

    @Test func unknownPrefixMiddleAndSuffixKeepTheirSpans() {
        let prefix = parser.parse("frobnicate open Safari")
        #expect(prefix.outcome != .complete)
        #expect(prefix.coverage.isComplete)

        let middle = parser.parse("wait 2 seconds and frobnicate then open Safari")
        #expect(middle.outcome != .complete)
        #expect(middle.coverage.isComplete)

        let suffix = parser.parse("wait 2 seconds and frobnicate the thing")
        #expect(suffix.outcome != .complete)
        #expect(suffix.coverage.isComplete)
    }

    @Test func dangerousTailFailsClosed() {
        let unsupported = parser.parse("open Safari and delete Downloads")
        #expect(unsupported.outcome == .unsupported)
        #expect(unsupported.coverage.isComplete)

        let unknown = parser.parse("open Safari and email Bob")
        #expect(unknown.outcome != .complete)
        #expect(unknown.coverage.isComplete)
    }

    @Test func evidenceAndExpectedSlotsAreReported() {
        let open = parser.parse("open").clauses.first { $0.kind == .openApplication }
        #expect(open?.expectedSlots == [.application])
        #expect(open?.evidence?.capability == .action(.openApplication))

        let wait = parser.parse("wait").clauses.first { $0.kind == .wait }
        #expect(wait?.expectedSlots == [.duration])

        let arrange = parser.parse("put Safari").clauses.first { $0.kind == .arrangeWindow }
        #expect(arrange?.expectedSlots == [.preset])

        let copy = parser.parse("copy").clauses.first { $0.kind == .copyText }
        #expect(copy?.expectedSlots == [.text])
    }

    @Test func inputLimitAcceptsTheBoundaryAndRejectsOneOver() {
        let atLimit = String(repeating: "a", count: CommandLimits.maximumCharacters)
        let parsed = parser.parse(atLimit)
        #expect(parsed.text == atLimit)
        #expect(!parsed.diagnostics.contains { $0.message.contains("2,000") })

        let over = String(repeating: "a", count: CommandLimits.maximumCharacters + 1)
        let rejected = parser.parse(over)
        #expect(rejected.outcome == .needsInput)
        #expect(rejected.clauses.isEmpty)
        #expect(rejected.text == over)
        #expect(rejected.diagnostics.contains { $0.message.contains("2,000") })
    }

    @Test func tokenLimitRejectsOverLimitInput() {
        let atLimit = "open " + Array(repeating: "app", count: CommandLimits.maximumTokens - 1).joined(separator: " ")
        #expect(CommandTokenizer.tokenize(atLimit).count == CommandLimits.maximumTokens)
        _ = parser.parse(atLimit)

        let over = "open " + Array(repeating: "app", count: CommandLimits.maximumTokens).joined(separator: " ")
        let rejected = parser.parse(over)
        #expect(rejected.outcome == .needsInput)
        #expect(rejected.diagnostics.contains { $0.message.contains("128 words") })
    }

    @Test func utf16LimitRejectsWideGraphemes() {
        let family = "👨‍👩‍👧‍👦"
        let unitCount = family.utf16.count
        let count = (CommandLimits.maximumUTF16Units / unitCount) + 1
        let text = String(repeating: family, count: count)
        #expect(text.count <= CommandLimits.maximumCharacters)
        #expect(text.utf16.count > CommandLimits.maximumUTF16Units)

        let rejected = parser.parse(text)
        #expect(rejected.outcome == .needsInput)
        #expect(rejected.clauses.isEmpty)
        #expect(rejected.diagnostics.contains { $0.message.contains("16,384") })
    }

    @Test func actionLimitRejectsTooManySteps() {
        let command = Array(repeating: "open Safari", count: CommandLimits.maximumActions + 1)
            .joined(separator: " and ")
        let parsed = parser.parse(command)
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.message.contains("at most 12") })
    }

    @Test func suggestionListRespectsVisibleLimit() {
        let engine = SuggestionEngine()
        #expect(engine.suggestions(for: "").count <= CommandLimits.maximumVisibleSuggestions)
    }

    private func scan(_ literal: String) -> String? {
        if case .success(let value) = CommandLiteralScanner.scan(literal, at: 0) {
            return value.value
        }
        return nil
    }
}
