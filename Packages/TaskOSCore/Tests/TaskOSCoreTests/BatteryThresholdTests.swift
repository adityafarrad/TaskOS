import Testing
import Foundation
@testable import TaskOSCore

@Suite("Battery threshold")
struct BatteryThresholdTests {
    @Test func baselineBelowDoesNotFireUntilCrossing() {
        var monitor = BatteryThresholdMonitor(comparator: .below, percentage: 20)
        monitor.establishBaseline(15)
        let first = monitor.observe(10)
        let second = monitor.observe(12)
        #expect(!first)
        #expect(!second)
    }

    @Test func firesWhenCrossingBelow() {
        var monitor = BatteryThresholdMonitor(comparator: .below, percentage: 20)
        monitor.establishBaseline(80)
        let crossed = monitor.observe(15)
        let again = monitor.observe(10)
        #expect(crossed)
        #expect(!again)
    }

    @Test func rearmsAtTwoPointMargin() {
        var monitor = BatteryThresholdMonitor(comparator: .below, percentage: 20)
        monitor.establishBaseline(80)
        let firstFire = monitor.observe(15)

        let notEnough = monitor.observe(21)
        let rearmed = monitor.observe(22)
        let secondFire = monitor.observe(19)

        #expect(firstFire)
        #expect(!notEnough)
        #expect(!rearmed)
        #expect(secondFire)
    }

    @Test func firesWhenCrossingAbove() {
        var monitor = BatteryThresholdMonitor(comparator: .above, percentage: 80)
        monitor.establishBaseline(20)
        let firstFire = monitor.observe(85)
        let again = monitor.observe(90)

        let notEnough = monitor.observe(79)
        let rearmed = monitor.observe(78)
        let secondFire = monitor.observe(85)

        #expect(firstFire)
        #expect(!again)
        #expect(!notEnough)
        #expect(!rearmed)
        #expect(secondFire)
    }

    @Test func unknownBatteryDoesNotFire() {
        var monitor = BatteryThresholdMonitor(comparator: .below, percentage: 20)
        monitor.establishBaseline(nil)
        let unknown = monitor.observe(nil)
        let value = monitor.observe(10)
        #expect(!unknown)
        #expect(!value)
    }

    @Test func registryUsesBaselineThenFiresOnCrossing() async {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let probe = ExecutionProbe()
        let coordinator = RunCoordinator(clock: clock) { definition, id in
            await probe.run(definition, id)
        }
        let suppressor = LifecycleSuppressor(clock: clock)
        let registry = EventTriggerRegistry(clock: clock, coordinator: coordinator, suppressor: suppressor)

        let definition = AutomationDefinition(
            name: "Battery",
            trigger: .batteryThreshold(BatteryThresholdTrigger(comparator: .below, percentage: 20)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
        await registry.register(definition)

        // First observation establishes the baseline (already below 20): no fire.
        #expect(await registry.handle(.batteryChanged(percentage: 15)).isEmpty)

        // Recharge above the margin, then drop below again.
        #expect(await registry.handle(.batteryChanged(percentage: 25)).isEmpty)
        #expect(await registry.handle(.batteryChanged(percentage: 18)) == [definition.id])

        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
    }
}
