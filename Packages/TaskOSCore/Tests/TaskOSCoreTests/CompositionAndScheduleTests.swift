import Testing
import Foundation
@testable import TaskOSCore

@Suite("Composition and schedules")
struct CompositionAndScheduleTests {
    private let parser = CommandParser()

    private func firstSchedule(_ text: String) -> ParsedSchedule? {
        parser.parse(text).clauses.first { $0.kind == .schedule }?.schedule
    }

    @Test func everyConnectorSeparatesActionsInOrder() {
        let connectors = [
            "then",
            "and then",
            "and",
            "also",
            ",",
            ";",
            "after that",
            "next",
            "followed by",
        ]

        for connector in connectors {
            let command = "open Notes \(connector) open Safari"
            let parsed = parser.parse(command)
            let names = parsed.clauses
                .filter { $0.kind == .openApplication }
                .flatMap(\.resourceNames)
            #expect(names == ["Notes", "Safari"], "\(connector): \(names)")
            #expect(parsed.outcome == .complete, "\(connector)")
            #expect(parsed.coverage.isComplete, "\(connector)")
        }
    }

    @Test func connectorsInsideCopyTextStayLiteral() {
        let parsed = parser.parse("copy \"a then b, c; d\"")
        #expect(parsed.clauses.first { $0.kind == .copyText }?.copyText == "a then b, c; d")
        #expect(parsed.outcome == .complete)
    }

    @Test func twelveActionsCompleteAndThirteenBlock() {
        let twelve = Array(repeating: "open Safari", count: 12).joined(separator: " and ")
        #expect(parser.parse(twelve).outcome == .complete)

        let thirteen = Array(repeating: "open Safari", count: 13).joined(separator: " and ")
        #expect(parser.parse(thirteen).outcome == .needsInput)
    }

    @Test func triggerMayBeFirstOrLastOnly() {
        #expect(parser.parse("every day at 9 am, then open Safari").outcome == .complete)
        #expect(parser.parse("open Safari, then every day at 9 am").outcome == .complete)

        let middle = parser.parse("open Safari, then every day at 9 am, then open Notes")
        #expect(middle.outcome == .needsInput)
        #expect(middle.diagnostics.contains { $0.message.contains("start or the end") })
    }

    @Test func twoTriggersAreRejected() {
        let parsed = parser.parse("every day at 9 am, then every 30 minutes, then open Safari")
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.message.contains("one trigger") })
    }

    @Test func eventTriggerAliasesAreRecognized() {
        #expect(parser.parse("when Safari launches, show a notification").outcome == .complete)
        #expect(parser.parse("when Safari quits, show a notification").outcome == .complete)
        #expect(parser.parse("when Safari exits, show a notification").outcome == .complete)
    }

    @Test func closesIsNoLongerAnAlias() {
        let parsed = parser.parse("when Safari closes")
        #expect(parsed.outcome != .complete)
        #expect(parsed.diagnostics.contains { $0.severity == .error })
    }

    @Test func everyScheduleFormIsRecognized() {
        #expect(firstSchedule("every day at 9 pm") == .daily(hour: 21, minute: 0))
        #expect(firstSchedule("every weekday at 5:30 pm") == .weekdays(Weekday.weekdays, hour: 17, minute: 30))
        #expect(
            firstSchedule("every monday and friday at 9 am")
                == .weekdays([.monday, .friday], hour: 9, minute: 0)
        )
        #expect(firstSchedule("every weekend at 10 am") == .weekdays(Weekday.weekend, hour: 10, minute: 0))
        #expect(firstSchedule("every 30 minutes") == .interval(1800))
        #expect(firstSchedule("in 45 minutes") == .relative(45 * 60))
        #expect(firstSchedule("once at 7 pm") == .once(hour: 19, minute: 0))
        #expect(
            firstSchedule("once on 2026-09-20 at 09:00")
                == .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)
        )
    }

    @Test func leapDayIsValidAndImpossibleDatesAreRejected() {
        #expect(
            firstSchedule("once on 2028-02-29 at 09:00")
                == .absolute(year: 2028, month: 2, day: 29, hour: 9, minute: 0)
        )
        #expect(firstSchedule("once on 2027-02-29 at 09:00") == .incomplete)
        #expect(firstSchedule("once on 2026-13-01 at 09:00") == .incomplete)
        #expect(firstSchedule("once on 2026-09-20 at 25:00") == .incomplete)
    }

    @Test func timeSyntaxIsConsistent() {
        #expect(firstSchedule("every day at 9 pm") == .daily(hour: 21, minute: 0))
        #expect(firstSchedule("every day at 9:00 pm") == .daily(hour: 21, minute: 0))
        #expect(firstSchedule("every day at 21:00") == .daily(hour: 21, minute: 0))
        #expect(firstSchedule("every day at 09:00") == .incomplete)

        #expect(parser.parse("every day at 9 pm").outcome == .complete)
        #expect(parser.parse("every day at 09:00").outcome == .needsInput)
        #expect(parser.parse("once on 2026-09-20 at 09:00").outcome == .complete)
    }

    @Test func canonicalSchedulePhrasesReparseToTheSameValue() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let absolute = Calendar.current.date(
            from: DateComponents(year: 2026, month: 9, day: 20, hour: 9, minute: 0)
        )!

        let samples: [(ScheduleTrigger, ParsedSchedule)] = [
            (.daily(hour: 9, minute: 0), .daily(hour: 9, minute: 0)),
            (.daily(hour: 21, minute: 30), .daily(hour: 21, minute: 30)),
            (.weekdays([.monday, .friday], hour: 17, minute: 15), .weekdays([.monday, .friday], hour: 17, minute: 15)),
            (.weekdays(Weekday.weekend, hour: 10, minute: 0), .weekdays(Weekday.weekend, hour: 10, minute: 0)),
            (.interval(every: 30 * 60, startingAt: base), .interval(30 * 60)),
            (.interval(every: 90, startingAt: base), .interval(90)),
            (.oneTime(absolute), .absolute(year: 2026, month: 9, day: 20, hour: 9, minute: 0)),
        ]

        for (schedule, expected) in samples {
            let phrase = CanonicalPhrase.text(for: schedule)
            let parsed = parser.parse(phrase)
            #expect(parsed.outcome == .complete, "\(phrase)")
            #expect(parsed.clauses.compactMap(\.schedule).first == expected, "\(phrase)")
        }
    }

    @Test func relativeDurationsRoundTripExactly() {
        for command in ["in 30 seconds", "in 1.5 minutes", "in 90 seconds"] {
            let document = ComposerDocument(text: "\(command), then open Safari")
            let reparsed = ComposerDocument(text: document.renderedText() + ", then open Safari")
            #expect(reparsed.trigger == document.trigger, "\(command) -> \(document.renderedText())")
        }
    }

    @Test func expandedListLimitSurfacesThroughComposer() {
        let thirteen = "open " + (1...13).map { "App\($0)" }.joined(separator: " and ")
        let document = ComposerDocument(text: thirteen)
        #expect(document.blockingParseMessage?.contains("12") == true)
    }

    @Test func absoluteOneTimeSurvivesComposition() {
        let expected = Calendar.current.date(
            from: DateComponents(year: 2026, month: 9, day: 20, hour: 9, minute: 0)
        )!

        var composer = ComposerDocument(text: "once on 2026-09-20 at 09:00, then open Safari")
        #expect(composer.trigger == .oneTime(expected))

        composer.setText("once on 2026-09-20 at 09:00, then open Safari, then wait 1 second")
        #expect(composer.trigger == .oneTime(expected))
    }
}
