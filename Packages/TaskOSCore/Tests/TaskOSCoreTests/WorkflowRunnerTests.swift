import Testing
import Foundation
@testable import TaskOSCore

private final class FakeExecutor: ActionExecutor, @unchecked Sendable {
    let supportedID: ActionID
    private let handler: @Sendable (ActionConfiguration) async -> ActionOutcome

    init(id: ActionID, handler: @escaping @Sendable (ActionConfiguration) async -> ActionOutcome) {
        self.supportedID = id
        self.handler = handler
    }

    convenience init(id: ActionID, outcome: ActionOutcome) {
        self.init(id: id) { _ in outcome }
    }

    func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        await handler(action)
    }
}

private func safariAction() -> ActionConfiguration {
    .openApplication(
        OpenApplicationAction(
            application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )
    )
}

private let notificationAction = ActionConfiguration.showNotification(
    ShowNotificationAction(title: "Done", message: "Finished")
)

private func waitForWaiter(_ clock: TestClock, limit: Int = 100_000) async {
    for _ in 0..<limit {
        if clock.waiterCount > 0 { return }
        await Task.yield()
    }
}

@Suite("Workflow runner")
struct WorkflowRunnerTests {
    @Test func runsActionsInOrderAndStopsOnFirstFailure() async {
        let clock = TestClock()
        let executors: [any ActionExecutor] = [
            FakeExecutor(id: .openApplication, outcome: .succeeded),
            FakeExecutor(id: .showNotification, outcome: .failed(ActionFailure(message: "Notification denied."))),
        ]
        let runner = WorkflowRunner(clock: clock, executors: executors)
        let definition = AutomationDefinition(
            name: "Fails at notification",
            trigger: .manual(ManualTrigger()),
            actions: [safariAction(), notificationAction, .wait(WaitAction(duration: 1))]
        )

        let record = await runner.run(definition)

        #expect(record.status == .failed)
        #expect(record.actions.map(\.actionID) == [.openApplication, .showNotification, .wait])
        #expect(record.actions[0].outcome == .succeeded)
        #expect(record.actions[1].outcome == .failed(ActionFailure(message: "Notification denied.")))
        #expect(record.actions[2].outcome == .notExecuted)
    }

    @Test func reportsTimeoutWhenExecutorDoesNotFinish() async {
        let clock = TestClock()
        let hanging = FakeExecutor(id: .openApplication) { _ in
            try? await Task.sleep(for: .seconds(3_600))
            return .succeeded
        }
        let timeouts = WorkflowRunner.Timeouts(
            defaultAction: 10,
            wholeWorkflow: 180,
            maximumCumulativeWait: 60
        )
        let runner = WorkflowRunner(clock: clock, executors: [hanging], timeouts: timeouts)
        let definition = AutomationDefinition(
            name: "Hangs",
            trigger: .manual(ManualTrigger()),
            actions: [safariAction()]
        )

        let task = Task { await runner.run(definition) }
        await waitForWaiter(clock)
        clock.advance(by: .seconds(10))
        let record = await task.value

        #expect(record.status == .timedOut)
        guard case .failed(let failure)? = record.actions.first?.outcome else {
            Issue.record("Expected a failure outcome")
            return
        }
        #expect(failure.isTimedOut)
    }

    @Test func rejectsCumulativeWaitBeyondLimit() async {
        let clock = TestClock()
        let timeouts = WorkflowRunner.Timeouts(
            defaultAction: 15,
            wholeWorkflow: 180,
            maximumCumulativeWait: 5
        )
        let runner = WorkflowRunner(clock: clock, executors: [], timeouts: timeouts)
        let definition = AutomationDefinition(
            name: "Too much waiting",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 10))]
        )

        let record = await runner.run(definition)

        #expect(record.status == .failed)
        guard case .failed(let failure)? = record.actions.first?.outcome else {
            Issue.record("Expected a failure outcome")
            return
        }
        #expect(!failure.isTimedOut)
    }

    @Test func waitUsesInjectedClock() async {
        let clock = TestClock()
        let runner = WorkflowRunner(clock: clock, executors: [])
        let definition = AutomationDefinition(
            name: "Wait only",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 5))]
        )

        let task = Task { await runner.run(definition) }
        await waitForWaiter(clock)
        clock.advance(by: .seconds(5))
        let record = await task.value

        #expect(record.status == .succeeded)
        #expect(record.actions.first?.outcome == .succeeded)
    }

    @Test func cancellationPreventsNextAction() async {
        let clock = TestClock()
        let executors: [any ActionExecutor] = [
            FakeExecutor(id: .showNotification, outcome: .succeeded)
        ]
        let runner = WorkflowRunner(clock: clock, executors: executors)
        let definition = AutomationDefinition(
            name: "Cancel mid-run",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 5)), notificationAction]
        )

        let task = Task { await runner.run(definition) }
        await waitForWaiter(clock)
        task.cancel()
        clock.advance(by: .seconds(5))
        let record = await task.value

        #expect(record.status == .cancelled)
        #expect(record.actions[0].outcome == .cancelled)
        #expect(record.actions[1].outcome == .notExecuted)
    }

    @Test func timeoutReturnsWithoutWaitingForNonCooperativeExecutor() async {
        let clock = TestClock()
        let flag = ReleaseFlag()
        let blocked = FakeExecutor(id: .openApplication) { _ in
            while !flag.isReleased {
                try? await Task.sleep(for: .milliseconds(1))
            }
            return .succeeded
        }
        let timeouts = WorkflowRunner.Timeouts(
            defaultAction: 10,
            wholeWorkflow: 180,
            maximumCumulativeWait: 60
        )
        let runner = WorkflowRunner(clock: clock, executors: [blocked], timeouts: timeouts)
        let definition = AutomationDefinition(
            name: "Ignores cancellation",
            trigger: .manual(ManualTrigger()),
            actions: [safariAction()]
        )

        let task = Task { await runner.run(definition) }
        await waitForWaiter(clock)
        clock.advance(by: .seconds(10))
        let record = await task.value
        flag.release()

        #expect(record.status == .timedOut)
        guard case .failed(let failure)? = record.actions.first?.outcome else {
            Issue.record("Expected a failure outcome")
            return
        }
        #expect(failure.isTimedOut)
    }
}

private final class ReleaseFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var released = false

    func release() {
        lock.lock()
        released = true
        lock.unlock()
    }

    var isReleased: Bool {
        lock.lock()
        defer { lock.unlock() }
        return released
    }
}
