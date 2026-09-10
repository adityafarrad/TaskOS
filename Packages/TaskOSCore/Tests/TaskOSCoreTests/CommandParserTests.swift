import Testing
import Foundation
@testable import TaskOSCore

@Suite("Command parser")
struct CommandParserTests {
    private let parser = CommandParser()

    @Test func emptyInputNeedsInput() {
        let result = parser.parse("")
        #expect(result.clauses.isEmpty)
        #expect(result.outcome == .needsInput)
    }

    @Test func openApplicationRecognized() {
        let result = parser.parse("open Safari")
        #expect(result.outcome == .complete)
        #expect(result.clauses.count == 1)
        #expect(result.clauses[0].kind == .openApplication)
        #expect(result.clauses[0].resourceNames == ["Safari"])
        #expect(result.clauses[0].span == SourceSpan(start: 0, end: 11))
        #expect(result.text.substring(in: result.clauses[0].span) == "open Safari")
    }

    @Test func openWithoutNameNeedsInput() {
        let result = parser.parse("open")
        #expect(result.outcome == .needsInput)
        #expect(result.clauses[0].resourceNames.isEmpty)
        #expect(result.hasErrors)
    }

    @Test func openWithMultipleResourceNames() {
        let result = parser.parse("open Safari and Notes")
        #expect(result.outcome == .complete)
        #expect(result.clauses.count == 1)
        #expect(result.clauses[0].resourceNames == ["Safari", "Notes"])
    }

    @Test func waitWithDuration() {
        let result = parser.parse("wait 1 second")
        #expect(result.outcome == .complete)
        #expect(result.clauses[0].kind == .wait)
        #expect(result.clauses[0].duration == 1)
    }

    @Test func waitFractionalDuration() {
        let result = parser.parse("wait 1.5 seconds")
        #expect(result.outcome == .complete)
        #expect(result.clauses[0].duration == 1.5)
    }

    @Test func waitWithoutDurationNeedsInput() {
        let result = parser.parse("wait")
        #expect(result.outcome == .needsInput)
        #expect(result.clauses[0].duration == nil)
    }

    @Test func waitOutOfRangeNeedsInput() {
        let result = parser.parse("wait 45 seconds")
        #expect(result.outcome == .needsInput)
        #expect(result.hasErrors)
    }

    @Test func notificationForms() {
        #expect(parser.parse("show a notification").outcome == .complete)
        #expect(parser.parse("show notification").outcome == .complete)
        #expect(parser.parse("notify").outcome == .complete)
        #expect(parser.parse("show a notification").clauses[0].kind == .showNotification)
    }

    @Test func multipleClausesAcrossConnectors() {
        let result = parser.parse("open Safari and wait 2 seconds")
        #expect(result.outcome == .complete)
        #expect(result.clauses.map(\.kind) == [.openApplication, .wait])
        #expect(result.clauses[1].duration == 2)
    }

    @Test func unsupportedClauseIsReported() {
        let result = parser.parse("open Safari then email my manager")
        #expect(result.outcome == .unsupported)
        #expect(result.clauses[0].kind == .openApplication)
        #expect(result.clauses[1].kind == .unsupported)
        #expect(result.clauses[1].detail != nil)
    }

    @Test func unknownWordingIsUnrecognized() {
        let result = parser.parse("frobnicate the widget")
        #expect(result.outcome == .unrecognized)
        #expect(result.clauses[0].kind == .unrecognized)
    }

    @Test func unsupportedAndUnrecognizedDoNotSilentlyDropText() {
        let result = parser.parse("open Safari and email Bob")
        let covered = result.clauses.reduce(0) { $0 + $1.span.length }
        #expect(covered > 0)
        #expect(result.clauses.allSatisfy { !$0.span.textIsEmpty })
    }
}

private extension SourceSpan {
    var textIsEmpty: Bool {
        length == 0
    }
}
