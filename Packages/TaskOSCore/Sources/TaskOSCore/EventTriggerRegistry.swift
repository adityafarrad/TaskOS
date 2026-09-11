import Foundation

public actor EventTriggerRegistry {
    private let clock: CoreClock
    private let coordinator: RunCoordinator
    private let suppressor: LifecycleSuppressor
    private var entries: [AutomationID: AutomationDefinition] = [:]
    private var batteryMonitors: [AutomationID: BatteryThresholdMonitor] = [:]

    public init(clock: CoreClock, coordinator: RunCoordinator, suppressor: LifecycleSuppressor) {
        self.clock = clock
        self.coordinator = coordinator
        self.suppressor = suppressor
    }

    public func register(_ definition: AutomationDefinition) {
        guard definition.trigger.isEventTrigger else { return }
        guard definition.validate().isValid else { return }
        entries[definition.id] = definition
    }

    public func unregister(_ id: AutomationID) {
        entries.removeValue(forKey: id)
        batteryMonitors.removeValue(forKey: id)
    }

    public func replaceAll(_ definitions: [AutomationDefinition]) {
        var next: [AutomationID: AutomationDefinition] = [:]
        for definition in definitions where definition.trigger.isEventTrigger {
            guard definition.validate().isValid else { continue }
            next[definition.id] = definition
        }
        entries = next
        batteryMonitors = batteryMonitors.filter { next[$0.key] != nil }
    }

    public func registeredCount() -> Int {
        entries.count
    }

    public func isRegistered(_ id: AutomationID) -> Bool {
        entries[id] != nil
    }

    @discardableResult
    public func handle(_ event: ObservedTriggerEvent) async -> [AutomationID] {
        if case .woke = event {
            await coordinator.updateSessionReadiness(true)
        }

        if case .batteryChanged(let value) = event {
            return await handleBattery(value)
        }

        let now = clock.now()
        var fired: [AutomationID] = []

        for (id, definition) in entries {
            guard definition.trigger.matches(event) else { continue }

            if case .applicationLifecycle(let trigger) = definition.trigger,
               await suppressor.isSuppressed(bundleIdentifier: trigger.application.identifier, at: now) {
                continue
            }

            let outcome = await coordinator.submit(definition, source: .automatic(definition.trigger.id))
            if outcome == .started || outcome == .queued {
                fired.append(id)
            }
        }

        return fired
    }

    private func handleBattery(_ value: Int?) async -> [AutomationID] {
        var fired: [AutomationID] = []

        for (id, definition) in entries {
            guard case .batteryThreshold(let trigger) = definition.trigger else { continue }

            if var monitor = batteryMonitors[id] {
                let shouldFire = monitor.observe(value)
                batteryMonitors[id] = monitor
                guard shouldFire else { continue }

                let outcome = await coordinator.submit(definition, source: .automatic(definition.trigger.id))
                if outcome == .started || outcome == .queued {
                    fired.append(id)
                }
            } else {
                var monitor = BatteryThresholdMonitor(
                    comparator: trigger.comparator,
                    percentage: trigger.percentage
                )
                monitor.establishBaseline(value)
                batteryMonitors[id] = monitor
            }
        }

        return fired
    }
}
