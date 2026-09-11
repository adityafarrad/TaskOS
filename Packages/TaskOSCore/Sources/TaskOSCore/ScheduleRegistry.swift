import Foundation

public actor ScheduleRegistry {
    private let clock: CoreClock
    private let calculator: ScheduleCalculator
    private let coordinator: RunCoordinator

    private var entries: [AutomationID: AutomationDefinition] = [:]
    private var task: Task<Void, Never>?
    private var generation = 0
    private var isRunning = false

    public init(clock: CoreClock, calculator: ScheduleCalculator, coordinator: RunCoordinator) {
        self.clock = clock
        self.calculator = calculator
        self.coordinator = coordinator
    }

    public func register(_ definition: AutomationDefinition) {
        guard case .schedule = definition.trigger else { return }
        guard definition.validate(relativeTo: clock.now()).isValid else { return }
        entries[definition.id] = definition
        wake()
    }

    public func unregister(_ id: AutomationID) {
        guard entries.removeValue(forKey: id) != nil else { return }
        wake()
    }

    public func replaceAll(_ definitions: [AutomationDefinition]) {
        var next: [AutomationID: AutomationDefinition] = [:]
        let now = clock.now()
        for definition in definitions {
            guard case .schedule = definition.trigger else { continue }
            guard definition.validate(relativeTo: now).isValid else { continue }
            next[definition.id] = definition
        }
        entries = next
        wake()
    }

    public func stop() {
        generation += 1
        task?.cancel()
        task = nil
        isRunning = false
    }

    public func registeredCount() -> Int {
        entries.count
    }

    public func isRegistered(_ id: AutomationID) -> Bool {
        entries[id] != nil
    }

    public func nextOccurrence(for id: AutomationID, after date: Date) -> Date? {
        guard let definition = entries[id], case .schedule(let schedule) = definition.trigger else {
            return nil
        }
        return calculator.nextOccurrence(of: schedule, after: date)
    }

    private func wake() {
        generation += 1
        task?.cancel()
        task = nil
        isRunning = false
        startIfNeeded()
    }

    private func startIfNeeded() {
        guard !isRunning, !entries.isEmpty else { return }
        isRunning = true
        let currentGeneration = generation
        task = Task { await self.runLoop(generation: currentGeneration) }
    }

    private func runLoop(generation loopGeneration: Int) async {
        while !entries.isEmpty, loopGeneration == generation {
            let now = clock.now()
            var earliestID: AutomationID?
            var earliestDate: Date?

            for (id, definition) in entries {
                guard case .schedule(let schedule) = definition.trigger else { continue }
                guard let next = calculator.nextOccurrence(of: schedule, after: now) else { continue }
                if earliestDate == nil || next < earliestDate! {
                    earliestDate = next
                    earliestID = id
                }
            }

            guard let fireDate = earliestDate, let id = earliestID else { break }

            let delay = fireDate.timeIntervalSince(now)
            if delay > 0 {
                do {
                    try await clock.sleep(for: .seconds(delay))
                } catch {
                    break
                }
            }

            guard loopGeneration == generation else { break }

            let fireNow = clock.now()
            guard fireNow >= fireDate else { continue }

            if let definition = entries[id], definition.validate(relativeTo: fireNow).isValid {
                _ = await coordinator.submit(definition, source: .automatic(.schedule))
            }
        }

        if loopGeneration == generation {
            isRunning = false
            task = nil
        }
    }
}
