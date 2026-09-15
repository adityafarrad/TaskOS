import Testing
import Foundation
@testable import TaskOSCore

@Suite("Event trigger registry", .serialized)
struct EventTriggerRegistryTests {
    private let safari = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")

    private func appTrigger(_ event: LifecycleEvent) -> AutomationDefinition {
        AutomationDefinition(
            name: "Lifecycle",
            trigger: .applicationLifecycle(ApplicationLifecycleTrigger(application: safari, event: event)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
    }

    private func context() -> (TestClock, ExecutionProbe, RunCoordinator, LifecycleSuppressor, EventTriggerRegistry) {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let probe = ExecutionProbe()
        let coordinator = RunCoordinator(clock: clock) { definition, id in
            await probe.run(definition, id)
        }
        let suppressor = LifecycleSuppressor(clock: clock, window: 3)
        let registry = EventTriggerRegistry(clock: clock, coordinator: coordinator, suppressor: suppressor)
        return (clock, probe, coordinator, suppressor, registry)
    }

    @Test func registerIgnoresNonEventTriggers() async {
        let (_, _, _, _, registry) = context()
        let manual = AutomationDefinition(
            name: "Manual",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )
        await registry.register(manual)
        #expect(await registry.registeredCount() == 0)
    }

    @Test func matchingEventFiresThroughCoordinator() async {
        let (_, probe, coordinator, _, registry) = context()
        let definition = appTrigger(.launched)
        await registry.register(definition)

        let fired = await registry.handle(.applicationLaunched(bundleIdentifier: "com.apple.Safari"))
        #expect(fired == [definition.id])
        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
        #expect(probe.started == [definition.id])
    }

    @Test func nonMatchingEventDoesNotFire() async {
        let (_, probe, _, _, registry) = context()
        await registry.register(appTrigger(.launched))

        let fired = await registry.handle(.applicationQuit(bundleIdentifier: "com.apple.Safari"))
        #expect(fired.isEmpty)
        #expect(probe.started.isEmpty)
    }

    @Test func suppressionBlocksCorrelatedLifecycleEvent() async {
        let (clock, probe, coordinator, suppressor, registry) = context()
        let definition = appTrigger(.launched)
        await registry.register(definition)

        await suppressor.suppress(bundleIdentifier: "com.apple.Safari")
        #expect(await registry.handle(.applicationLaunched(bundleIdentifier: "com.apple.Safari")).isEmpty)

        clock.advance(by: .seconds(4))
        let fired = await registry.handle(.applicationLaunched(bundleIdentifier: "com.apple.Safari"))
        #expect(fired == [definition.id])

        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
    }

    @Test func wakeEventFiresAndRestoresSessionReadiness() async {
        let (_, probe, coordinator, _, registry) = context()
        let definition = AutomationDefinition(
            name: "Wake",
            trigger: .wake(WakeTrigger()),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
        await registry.register(definition)

        await coordinator.updateSessionReadiness(false)
        let fired = await registry.handle(.woke)
        #expect(fired == [definition.id])

        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
        #expect(await coordinator.status().isSessionReady)
    }

    @Test func unregisterStopsFiring() async {
        let (_, _, _, _, registry) = context()
        let definition = appTrigger(.quit)
        await registry.register(definition)
        await registry.unregister(definition.id)

        #expect(await registry.handle(.applicationQuit(bundleIdentifier: "com.apple.Safari")).isEmpty)
    }

    @Test func replaceAllKeepsOnlyValidEventTriggers() async {
        let (_, _, _, _, registry) = context()
        let valid = appTrigger(.launched)
        let manual = AutomationDefinition(
            name: "Manual",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )
        await registry.replaceAll([valid, manual])
        #expect(await registry.registeredCount() == 1)
        #expect(await registry.isRegistered(valid.id))
    }

    @Test func anotherWorkflowForSameAppAlsoFires() async {
        let (_, probe, coordinator, _, registry) = context()
        let first = appTrigger(.launched)
        let second = AutomationDefinition(
            id: AutomationID(),
            name: "Second",
            trigger: .applicationLifecycle(ApplicationLifecycleTrigger(application: safari, event: .launched)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
        await registry.register(first)
        await registry.register(second)

        let fired = await registry.handle(.applicationLaunched(bundleIdentifier: "com.apple.Safari"))
        #expect(Set(fired) == Set([first.id, second.id]))
        await probe.awaitStarted(2)
        await coordinator.waitUntilIdle()
    }

    @Test func reRegisteringABatteryTriggerReplacesTheMonitor() async {
        let (clock, probe, coordinator, _, registry) = context()
        let original = AutomationDefinition(
            name: "Battery",
            trigger: .batteryThreshold(BatteryThresholdTrigger(comparator: .below, percentage: 20)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
        await registry.register(original)
        _ = await registry.handle(.batteryChanged(percentage: 25))
        let first = await registry.handle(.batteryChanged(percentage: 19))
        #expect(first == [original.id])
        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
        clock.advance(by: .seconds(11))

        let updated = AutomationDefinition(
            id: original.id,
            name: original.name,
            revision: original.revision.next(),
            trigger: .batteryThreshold(BatteryThresholdTrigger(comparator: .above, percentage: 80)),
            actions: original.actions
        )
        await registry.register(updated)

        #expect(await registry.handle(.batteryChanged(percentage: 79)).isEmpty)
        let fired = await registry.handle(.batteryChanged(percentage: 85))
        #expect(fired == [original.id])

        await probe.awaitStarted(2)
        await coordinator.waitUntilIdle()
    }

    @Test func replaceAllResetsOnlyChangedBatteryMonitors() async {
        let (_, probe, coordinator, _, registry) = context()
        let definition = AutomationDefinition(
            name: "Battery",
            trigger: .batteryThreshold(BatteryThresholdTrigger(comparator: .below, percentage: 20)),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )
        await registry.register(definition)
        _ = await registry.handle(.batteryChanged(percentage: 25))

        let changed = AutomationDefinition(
            id: definition.id,
            name: definition.name,
            revision: definition.revision.next(),
            trigger: .batteryThreshold(BatteryThresholdTrigger(comparator: .below, percentage: 40)),
            actions: definition.actions
        )
        await registry.replaceAll([changed])

        #expect(await registry.handle(.batteryChanged(percentage: 35)).isEmpty)
        #expect(await registry.handle(.batteryChanged(percentage: 45)).isEmpty)
        let fired = await registry.handle(.batteryChanged(percentage: 38))
        #expect(fired == [definition.id])

        await probe.awaitStarted(1)
        await coordinator.waitUntilIdle()
    }
}
