import Testing
import Foundation
import TaskOSCore

@Suite("Schedule grammar and composer")
struct ScheduleComposerTests {
    private let parser = CommandParser()

    private func firstSchedule(_ text: String) -> ParsedClause? {
        parser.parse(text).clauses.first { $0.kind == .schedule }
    }

    @Test func parsesDailyTime() {
        let clause = firstSchedule("every day at 9 am")
        #expect(clause?.schedule == .daily(hour: 9, minute: 0))
    }

    @Test func parsesDaily24HourTime() {
        let clause = firstSchedule("every day at 21:00")
        #expect(clause?.schedule == .daily(hour: 21, minute: 0))
    }

    @Test func parsesWeekdays() {
        let clause = firstSchedule("every weekday at 5:30 pm")
        #expect(clause?.schedule == .weekdays(Weekday.weekdays, hour: 17, minute: 30))
    }

    @Test func parsesSelectedWeekdays() {
        let clause = firstSchedule("every monday and friday at 9:00 am")
        #expect(clause?.schedule == .weekdays([.monday, .friday], hour: 9, minute: 0))
    }

    @Test func parsesWeekend() {
        let clause = firstSchedule("every weekend at 10:00 am")
        #expect(clause?.schedule == .weekdays(Weekday.weekend, hour: 10, minute: 0))
    }

    @Test func parsesInterval() {
        #expect(firstSchedule("every 30 minutes")?.schedule == .interval(1800))
        #expect(firstSchedule("every 2 hours")?.schedule == .interval(7200))
        #expect(firstSchedule("every minute")?.schedule == .interval(60))
    }

    @Test func parsesRelativeOneTime() {
        #expect(firstSchedule("in 45 minutes")?.schedule == .relative(45 * 60))
    }

    @Test func parsesOnce() {
        #expect(firstSchedule("once at 7:00 pm")?.schedule == .once(hour: 19, minute: 0))
    }

    @Test func bareAmbiguousHourRequiresClarification() {
        let parsed = parser.parse("every day at 9")
        #expect(parsed.outcome == .needsInput)
        #expect(parsed.diagnostics.contains { $0.severity == .error })
    }

    @Test func scheduleWithActionsParsesComplete() {
        let parsed = parser.parse("every day at 9 am, then show a notification")
        #expect(parsed.outcome == .complete)
        #expect(parsed.recognizedActionClauses.count == 1)
    }

    @Test func composerExtractsTriggerFromText() {
        var document = ComposerDocument(text: "every weekday at 8:15 am, then show a notification")
        #expect(document.trigger == .weekdays(Weekday.weekdays, hour: 8, minute: 15))
        #expect(document.actions.count == 1)
        #expect(!document.hasUnresolvedText)
    }

    @Test func composerBuildsScheduleDefinition() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let document = ComposerDocument(text: "in 30 minutes, then show a notification")
        let definition = document.makeDefinition(name: "Later", now: now)

        guard case .schedule(.oneTime(let date)) = definition?.trigger else {
            Issue.record("Expected a one-time schedule trigger")
            return
        }
        #expect(date == now.addingTimeInterval(30 * 60))
    }

    @Test func pastDueOneTimeDefinitionIsRejected() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        var document = ComposerDocument()
        document.setTrigger(.oneTime(now.addingTimeInterval(-60)))
        document.addAction(.showNotification(title: "TaskOS", message: ""))
        #expect(document.makeDefinition(name: "Past", now: now) == nil)
    }

    @Test func setTriggerRendersParseableText() {
        var document = ComposerDocument()
        document.addAction(.showNotification(title: "TaskOS", message: ""))
        document.setTrigger(.daily(hour: 9, minute: 0))
        #expect(document.text.contains("Every day at 9:00 AM"))

        var reparsed = ComposerDocument(text: document.text)
        #expect(reparsed.trigger == .daily(hour: 9, minute: 0))
        #expect(reparsed.actions.count == 1)
    }

    @Test func undoRestoresPreviousTrigger() {
        var document = ComposerDocument()
        document.addAction(.showNotification(title: "TaskOS", message: ""))
        document.setTrigger(.daily(hour: 9, minute: 0))
        document.setTrigger(.daily(hour: 10, minute: 0))
        document.undo()
        #expect(document.trigger == .daily(hour: 9, minute: 0))
    }

    @Test func manualTriggerByDefault() {
        let document = ComposerDocument(text: "show a notification")
        #expect(document.trigger == .manual)
        guard case .manual = document.makeDefinition(name: "M")?.trigger else {
            Issue.record("Expected a manual trigger")
            return
        }
    }
}
