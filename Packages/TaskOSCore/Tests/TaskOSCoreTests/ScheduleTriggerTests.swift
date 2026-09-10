import Testing
import Foundation
import TaskOSCore

@Suite("Schedule trigger")
struct ScheduleTriggerTests {
    private let newYork = TimeZone(identifier: "America/New_York")!
    private let utc = TimeZone(identifier: "UTC")!

    private func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0,
        in timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func parts(_ date: Date, in timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    // MARK: One-time

    @Test func oneTimeFutureProducesSingleOccurrence() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let scheduled = date(2026, 9, 20, 14, 30, in: newYork)
        let after = date(2026, 9, 10, 9, 0, in: newYork)

        let occurrences = calculator.nextOccurrences(of: .oneTime(scheduled), after: after, count: 3)
        #expect(occurrences == [scheduled])
    }

    @Test func oneTimePastProducesNoOccurrence() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let scheduled = date(2026, 9, 1, 14, 30, in: newYork)
        let after = date(2026, 9, 10, 9, 0, in: newYork)

        #expect(calculator.nextOccurrences(of: .oneTime(scheduled), after: after).isEmpty)
    }

    @Test func oneTimePastDueFailsValidationRelativeToNow() {
        let trigger = ScheduleTrigger.oneTime(date(2026, 9, 1, 9, 0, in: newYork))
        let now = date(2026, 9, 10, 9, 0, in: newYork)

        #expect(!trigger.validate(relativeTo: now).isValid)
        #expect(trigger.isPastDue(relativeTo: now))
        #expect(trigger.validate(relativeTo: nil).isValid)
    }

    // MARK: Daily

    @Test func dailyProducesNextThreeIncreasingOccurrences() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let after = date(2026, 9, 10, 10, 0, in: newYork)

        let occurrences = calculator.nextOccurrences(of: .daily(hour: 9, minute: 0), after: after)
        #expect(occurrences.count == 3)

        let expectedDays = [11, 12, 13]
        for (occurrence, day) in zip(occurrences, expectedDays) {
            let p = parts(occurrence, in: newYork)
            #expect(p.day == day)
            #expect(p.hour == 9)
            #expect(p.minute == 0)
        }
        #expect(occurrences == occurrences.sorted())
    }

    @Test func dailyDoesNotFireWhenNowEqualsScheduledTime() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let now = date(2026, 9, 10, 9, 0, in: newYork)

        let next = calculator.nextOccurrence(of: .daily(hour: 9, minute: 0), after: now)
        #expect(next != nil)
        #expect(parts(next!, in: newYork).day == 11)
    }

    @Test func dailySkipsNonexistentDaylightSavingTime() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let after = date(2026, 3, 8, 0, 30, in: newYork)

        let next = calculator.nextOccurrence(of: .daily(hour: 2, minute: 30), after: after)
        #expect(next != nil)

        let p = parts(next!, in: newYork)
        #expect(p.month == 3)
        #expect(p.day == 9)
        #expect(p.hour == 2)
        #expect(p.minute == 30)
    }

    @Test func dailyUsesFirstRepeatedDaylightSavingTime() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let after = date(2026, 11, 1, 0, 30, in: newYork)

        let occurrences = calculator.nextOccurrences(of: .daily(hour: 1, minute: 30), after: after, count: 2)

        let firstExpected = date(2026, 11, 1, 5, 30, in: utc)
        let secondExpected = date(2026, 11, 2, 6, 30, in: utc)

        #expect(occurrences[0] == firstExpected)
        #expect(occurrences[1] == secondExpected)
    }

    // MARK: Weekdays

    @Test func weekdaysOnlyReturnSelectedDays() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let after = date(2026, 9, 13, 12, 0, in: newYork)

        let occurrences = calculator.nextOccurrences(
            of: .weekdays([.monday, .friday], hour: 9, minute: 0),
            after: after,
            count: 2
        )

        let first = parts(occurrences[0], in: newYork)
        let second = parts(occurrences[1], in: newYork)
        #expect(first.day == 14)
        #expect(first.hour == 9)
        #expect(second.day == 18)
        #expect(second.hour == 9)
    }

    @Test func emptyWeekdaySetProducesNoOccurrence() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        #expect(calculator.nextOccurrences(of: .weekdays([], hour: 9, minute: 0), after: Date()).isEmpty)
        #expect(!ScheduleTrigger.weekdays([], hour: 9, minute: 0).validate().isValid)
    }

    // MARK: Interval

    @Test func intervalAlignsToAnchor() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let anchor = date(2026, 9, 10, 9, 0, in: newYork)
        let schedule = ScheduleTrigger.interval(every: 30 * 60, startingAt: anchor)

        let next = calculator.nextOccurrence(of: schedule, after: date(2026, 9, 10, 9, 10, in: newYork))
        let p = parts(next!, in: newYork)
        #expect(p.hour == 9)
        #expect(p.minute == 30)
    }

    @Test func intervalSkipsMissedBacklog() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let anchor = date(2026, 9, 10, 9, 0, in: newYork)
        let schedule = ScheduleTrigger.interval(every: 30 * 60, startingAt: anchor)

        let next = calculator.nextOccurrence(of: schedule, after: date(2026, 9, 11, 10, 0, in: newYork))
        let p = parts(next!, in: newYork)
        #expect(p.day == 11)
        #expect(p.hour == 10)
        #expect(p.minute == 30)
    }

    @Test func intervalBeforeAnchorStartsAtAnchor() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let anchor = date(2026, 9, 10, 9, 0, in: newYork)
        let schedule = ScheduleTrigger.interval(every: 15 * 60, startingAt: anchor)

        let occurrences = calculator.nextOccurrences(
            of: schedule,
            after: date(2026, 9, 10, 8, 0, in: newYork),
            count: 3
        )
        #expect(occurrences[0] == anchor)
        #expect(occurrences[1] == anchor.addingTimeInterval(15 * 60))
    }

    // MARK: Validation

    @Test func intervalValidationBounds() {
        let anchor = Date(timeIntervalSince1970: 0)
        #expect(ScheduleTrigger.interval(every: 15 * 60, startingAt: anchor).validate().isValid)
        #expect(ScheduleTrigger.interval(every: 24 * 60 * 60, startingAt: anchor).validate().isValid)
        #expect(!ScheduleTrigger.interval(every: 14 * 60, startingAt: anchor).validate().isValid)
        #expect(!ScheduleTrigger.interval(every: 24 * 60 * 60 + 1, startingAt: anchor).validate().isValid)
    }

    @Test func timeOfDayValidationBounds() {
        #expect(ScheduleTrigger.daily(hour: 0, minute: 0).validate().isValid)
        #expect(ScheduleTrigger.daily(hour: 23, minute: 59).validate().isValid)
        #expect(!ScheduleTrigger.daily(hour: 24, minute: 0).validate().isValid)
        #expect(!ScheduleTrigger.daily(hour: 9, minute: 60).validate().isValid)
    }

    // MARK: Time zone and definition integration

    @Test func occurrencesFollowCalculatorTimeZone() {
        let calculator = ScheduleCalculator(timeZone: newYork)
        let next = calculator.nextOccurrence(
            of: .daily(hour: 9, minute: 0),
            after: date(2026, 9, 10, 0, 0, in: newYork)
        )
        #expect(parts(next!, in: newYork).hour == 9)
        #expect(parts(next!, in: utc).hour == 13)
    }

    @Test func triggerExposesSchedule() {
        let trigger = TriggerConfiguration.schedule(.daily(hour: 9, minute: 0))
        #expect(trigger.id == .schedule)
        #expect(trigger.schedule != nil)
        #expect(trigger.validate().isValid)
    }

    @Test func scheduleDefinitionRoundTripsThroughCoding() throws {
        let definition = AutomationDefinition(
            name: "Morning",
            trigger: .schedule(.weekdays([.monday, .wednesday], hour: 8, minute: 15)),
            actions: [.wait(WaitAction(duration: 1))]
        )

        let data = try AutomationCoding.encode(definition)
        let decoded = try AutomationCoding.decode(data)
        #expect(decoded.trigger == definition.trigger)
    }

    @Test func definitionPastDueOneTimeFailsOnlyWithReferenceDate() {
        let scheduled = date(2020, 1, 1, 9, 0, in: utc)
        let definition = AutomationDefinition(
            name: "Past",
            trigger: .schedule(.oneTime(scheduled)),
            actions: [.wait(WaitAction(duration: 1))]
        )

        #expect(definition.validate().isValid)
        #expect(!definition.validate(relativeTo: date(2026, 1, 1, 9, 0, in: utc)).isValid)
    }
}
