import Foundation

public actor WorkflowRunner {
    public struct Timeouts: Sendable, Equatable {
        public var defaultAction: TimeInterval
        public var perAction: [ActionID: TimeInterval]
        public var wholeWorkflow: TimeInterval
        public var maximumCumulativeWait: TimeInterval

        public init(
            defaultAction: TimeInterval,
            perAction: [ActionID: TimeInterval] = [:],
            wholeWorkflow: TimeInterval,
            maximumCumulativeWait: TimeInterval
        ) {
            self.defaultAction = defaultAction
            self.perAction = perAction
            self.wholeWorkflow = wholeWorkflow
            self.maximumCumulativeWait = maximumCumulativeWait
        }

        public static let `default` = Timeouts(
            defaultAction: 15,
            perAction: [
                .openApplication: 15,
                .showNotification: 5,
            ],
            wholeWorkflow: 180,
            maximumCumulativeWait: 60
        )

        func timeout(for id: ActionID) -> TimeInterval {
            perAction[id] ?? defaultAction
        }
    }

    private enum RaceResult: Sendable {
        case completed(ActionOutcome)
        case timedOut
    }

    private let clock: CoreClock
    private let executors: [ActionID: any ActionExecutor]
    private let timeouts: Timeouts

    public init(clock: CoreClock, executors: [any ActionExecutor], timeouts: Timeouts = .default) {
        self.clock = clock
        var map: [ActionID: any ActionExecutor] = [:]
        for executor in executors {
            map[executor.supportedID] = executor
        }
        self.executors = map
        self.timeouts = timeouts
    }

    public func run(_ definition: AutomationDefinition) async -> RunRecord {
        let startedAt = clock.now()
        var records: [ActionRunRecord] = []
        var status: RunStatus = .succeeded
        var cumulativeWait: TimeInterval = 0
        var stopped = false

        for (index, action) in definition.actions.enumerated() {
            if Task.isCancelled {
                records.append(ActionRunRecord(index: index, actionID: action.id, outcome: .cancelled, duration: 0))
                status = .cancelled
                stopped = true
                break
            }

            if clock.now().timeIntervalSince(startedAt) >= timeouts.wholeWorkflow {
                records.append(ActionRunRecord(index: index, actionID: action.id, outcome: .notExecuted, duration: 0))
                status = .timedOut
                stopped = true
                break
            }

            let actionStart = clock.now()
            let outcome = await perform(action, cumulativeWait: &cumulativeWait)
            let duration = clock.now().timeIntervalSince(actionStart)
            records.append(ActionRunRecord(index: index, actionID: action.id, outcome: outcome, duration: duration))

            switch outcome {
            case .succeeded:
                continue
            case .failed(let failure):
                status = failure.isTimedOut ? .timedOut : .failed
                stopped = true
            case .cancelled:
                status = .cancelled
                stopped = true
            case .notExecuted:
                status = .failed
                stopped = true
            }
            break
        }

        if stopped, records.count < definition.actions.count {
            for index in records.count..<definition.actions.count {
                let action = definition.actions[index]
                records.append(ActionRunRecord(index: index, actionID: action.id, outcome: .notExecuted, duration: 0))
            }
        }

        return RunRecord(
            automationID: definition.id,
            revision: definition.revision,
            automationName: definition.name,
            status: status,
            startedAt: startedAt,
            finishedAt: clock.now(),
            actions: records
        )
    }

    private func perform(_ action: ActionConfiguration, cumulativeWait: inout TimeInterval) async -> ActionOutcome {
        if case .wait(let waitAction) = action {
            let total = cumulativeWait + waitAction.duration
            guard total <= timeouts.maximumCumulativeWait else {
                return .failed(ActionFailure(message: "Cumulative wait would exceed \(Int(timeouts.maximumCumulativeWait)) seconds."))
            }
            cumulativeWait = total
            do {
                try await clock.sleep(for: .seconds(waitAction.duration))
                return .succeeded
            } catch {
                return .cancelled
            }
        }

        guard let executor = executors[action.id] else {
            return .failed(ActionFailure(message: "No executor is registered for '\(action.id.stableID)'."))
        }
        return await executeWithTimeout(action, executor: executor)
    }

    private func executeWithTimeout(_ action: ActionConfiguration, executor: any ActionExecutor) async -> ActionOutcome {
        let timeout = timeouts.timeout(for: action.id)
        let clock = self.clock

        return await withTaskGroup(of: RaceResult.self) { group in
            group.addTask {
                .completed(await executor.execute(action))
            }
            group.addTask {
                do {
                    try await clock.sleep(for: .seconds(timeout))
                } catch {
                    return .timedOut
                }
                return .timedOut
            }

            let first = await group.next() ?? .timedOut
            group.cancelAll()

            switch first {
            case .completed(let outcome):
                return outcome
            case .timedOut:
                return .failed(ActionFailure(message: "Action timed out after \(timeout) seconds.", isTimedOut: true))
            }
        }
    }
}
