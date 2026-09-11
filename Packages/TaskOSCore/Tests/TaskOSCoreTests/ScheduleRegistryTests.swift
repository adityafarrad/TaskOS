import Testing
import Foundation
@testable import TaskOSCore

@Suite("Schedule registry", .serialized)
struct ScheduleRegistryTests {
    private let utc = TimeZone(identifier: "UTC")!

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func scheduled(_ schedule: ScheduleTrigger, name: String = "Scheduled") -> AutomationDefinition {
        AutomationDefinition(
            name: name,
            trigger: .schedule(schedule),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
    }

    private func context(now: Date) -> (TestClock, ExecutionProbe, RunCoordinator, ScheduleRegistry) {
        let clock = TestClock(now: now)
        let probe = ExecutionProbe()
        let coordinator = RunCoordinator(clock: clock) { definition, id in
            await probe.run(definition, id)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        let registry = ScheduleRegistry(
            clock: clock,
            calculator: ScheduleCalculator(calendar: calendar),
            coordinator: coordinator
        )
        return (clock, probe, coordinator, registry)
    }

    private func waitArmed(_ clock: TestClock) async {
        for _ in 0..<100_000 {
            if clock.waiterCount > 0 { return }
            await Task.yield()
        }
    }

    @Test func firesDailyScheduleThroughCoordinator() async {
        let (clock, probe, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let definition = scheduled(.daily(hour: 9, minute: 0))

        await registry.register(definition)
        #expect(await registry.registeredCount() == 1)
        await waitArmed(clock)

        clock.advance(by: .seconds(3600))
        await probe.awaitStarted(1)
        #expect(probe.started == [definition.id])

        await registry.stop()
    }

    @Test func skipsMissedOccurrences() async {
        let (clock, probe, _, registry) = context(now: date(2026, 9, 10, 10, 0))
        let definition = scheduled(.daily(hour: 9, minute: 0))

        await registry.register(definition)
        await waitArmed(clock)
        clock.advance(by: .seconds(30 * 60))
        await Task.yield()
        #expect(probe.started.isEmpty)

        await registry.stop()
    }

    @Test func intervalFiresRepeatedly() async {
        let anchor = date(2026, 9, 10, 8, 0)
        let (clock, probe, _, registry) = context(now: anchor)
        let definition = scheduled(.interval(every: 15 * 60, startingAt: anchor))

        await registry.register(definition)
        await waitArmed(clock)
        clock.advance(by: .seconds(15 * 60))
        await probe.awaitStarted(1)

        await waitArmed(clock)
        clock.advance(by: .seconds(15 * 60))
        await probe.awaitStarted(2)

        #expect(probe.started.count == 2)
        await registry.stop()
    }

    @Test func unregisterStopsFiring() async {
        let (clock, probe, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let first = scheduled(.daily(hour: 9, minute: 0), name: "First")
        let second = scheduled(.daily(hour: 9, minute: 0), name: "Second")

        await registry.register(first)
        await registry.register(second)
        await registry.unregister(first.id)
        await waitArmed(clock)

        clock.advance(by: .seconds(3600))
        await probe.awaitStarted(1)
        #expect(probe.started == [second.id])

        await registry.stop()
    }

    @Test func pastDueOneTimeIsNotRegistered() async {
        let now = date(2026, 9, 10, 10, 0)
        let (_, _, _, registry) = context(now: now)
        let definition = scheduled(.oneTime(now.addingTimeInterval(-3600)))

        await registry.register(definition)
        #expect(await registry.registeredCount() == 0)
    }

    @Test func invalidDefinitionIsNotRegistered() async {
        let (_, _, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let invalid = AutomationDefinition(
            name: "   ",
            trigger: .schedule(.daily(hour: 9, minute: 0)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )

        await registry.register(invalid)
        #expect(await registry.registeredCount() == 0)
    }

    @Test func replaceAllKeepsOnlyEnabledSchedules() async {
        let (_, _, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let scheduledDefinition = scheduled(.daily(hour: 9, minute: 0))
        let manual = AutomationDefinition(
            name: "Manual",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )

        await registry.replaceAll([scheduledDefinition, manual])
        #expect(await registry.registeredCount() == 1)
        #expect(await registry.isRegistered(scheduledDefinition.id))

        await registry.stop()
    }

    @Test func oneTimeFiresWhenClockOvershoots() async {
        let (clock, probe, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let fireAt = date(2026, 9, 10, 9, 0)
        let definition = scheduled(.oneTime(fireAt))

        await registry.register(definition)
        await waitArmed(clock)

        clock.advance(by: .seconds(3600 + 5))
        await probe.awaitStarted(1)
        #expect(probe.started == [definition.id])

        await registry.stop()
    }

    @Test func oneTimeFiresOnce() async {
        let (clock, probe, _, registry) = context(now: date(2026, 9, 10, 8, 0))
        let definition = scheduled(.oneTime(date(2026, 9, 10, 9, 0)))
        await registry.register(definition)
        await waitArmed(clock)

        clock.advance(by: .seconds(3600))
        await probe.awaitStarted(1)
        clock.advance(by: .seconds(3600))
        await Task.yield()

        #expect(probe.started == [definition.id])
        await registry.stop()
    }
}
