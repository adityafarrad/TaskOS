import Testing
import Foundation
@testable import TaskOSCore

final class ExecutionProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var startedIDs: [AutomationID] = []
    private var startWaiters: [(threshold: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var gateOpen = false
    private var gateWaiters: [CheckedContinuation<Void, Never>] = []

    var blocking = false

    var started: [AutomationID] {
        withLock { startedIDs }
    }

    @discardableResult
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    func open() {
        let waiters = withLock { () -> [CheckedContinuation<Void, Never>] in
            gateOpen = true
            let pending = gateWaiters
            gateWaiters.removeAll()
            return pending
        }
        for waiter in waiters {
            waiter.resume()
        }
    }

    func awaitStarted(_ threshold: Int) async {
        await withCheckedContinuation { continuation in
            let alreadyStarted = withLock { () -> Bool in
                if startedIDs.count >= threshold {
                    return true
                }
                startWaiters.append((threshold, continuation))
                return false
            }
            if alreadyStarted {
                continuation.resume()
            }
        }
    }

    func run(_ definition: AutomationDefinition, _ id: UUID) async -> RunRecord {
        let ready = withLock {
            () -> ([CheckedContinuation<Void, Never>], Bool) in
            startedIDs.append(definition.id)
            let waiters = startWaiters
                .filter { $0.threshold <= startedIDs.count }
                .map(\.continuation)
            startWaiters.removeAll { $0.threshold <= startedIDs.count }
            return (waiters, blocking && !gateOpen)
        }
        for waiter in ready.0 {
            waiter.resume()
        }

        if ready.1 {
            await withTaskCancellationHandler {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    withLock { gateWaiters.append(continuation) }
                }
            } onCancel: {
                let waiters = withLock { () -> [CheckedContinuation<Void, Never>] in
                    let pending = gateWaiters
                    gateWaiters.removeAll()
                    return pending
                }
                for waiter in waiters {
                    waiter.resume()
                }
            }
        }

        return RunRecord(
            id: id,
            automationID: definition.id,
            revision: definition.revision,
            automationName: definition.name,
            status: .succeeded,
            startedAt: Date(timeIntervalSince1970: 0),
            finishedAt: Date(timeIntervalSince1970: 0),
            actions: []
        )
    }
}

@Suite("Run coordinator")
struct RunCoordinatorTests {
    private func workflow(_ name: String = "Workflow") -> AutomationDefinition {
        AutomationDefinition(
            name: name,
            trigger: .schedule(.daily(hour: 9, minute: 0)),
            actions: [.wait(WaitAction(duration: 1))]
        )
    }

    private func makeCoordinator(
        clock: TestClock,
        probe: ExecutionProbe,
        limits: RunCoordinator.Limits = .default,
        maximumEventLog: Int = RunCoordinator.maximumEventLog
    ) -> RunCoordinator {
        RunCoordinator(clock: clock, limits: limits, maximumEventLog: maximumEventLog) { definition, id in
            await probe.run(definition, id)
        }
    }

    @Test func manualRunStartsAndExecutes() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow()

        let outcome = await coordinator.submit(definition, source: .manual)
        #expect(outcome == .started)
        await coordinator.waitUntilIdle()
        #expect(probe.started == [definition.id])
    }

    @Test func automaticRunStarts() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow()

        let outcome = await coordinator.submit(definition, source: .automatic(.schedule))
        #expect(outcome == .started)
        await coordinator.waitUntilIdle()
        #expect(probe.started == [definition.id])
        #expect(await coordinator.status().recentEvents.isEmpty)
    }

    @Test func automaticOneTimeJustFiredIsAccepted() async {
        let clock = TestClock(now: Date(timeIntervalSince1970: 1_000))
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = AutomationDefinition(
            name: "Once",
            trigger: .schedule(.oneTime(Date(timeIntervalSince1970: 999))),
            actions: [.showNotification(ShowNotificationAction(title: "TaskOS", message: ""))]
        )

        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await coordinator.waitUntilIdle()
        #expect(probe.started == [definition.id])
    }

    @Test func duplicateAutomaticRunIsSuppressedWhileRunning() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow()

        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)

        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .suppressedDuplicate)
        let events = await coordinator.status().recentEvents
        #expect(events.map(\.kind) == [.duplicateSuppressed])

        probe.open()
        await coordinator.waitUntilIdle()
    }

    @Test func duplicateAutomaticRunIsSuppressedWhileQueued() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .queued)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .suppressedDuplicate)

        probe.open()
        await coordinator.waitUntilIdle()
    }

    @Test func cooldownSuppressesRapidAutomaticRepeat() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow()

        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await coordinator.waitUntilIdle()
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .suppressedCooldown)

        clock.advance(by: .seconds(11))
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await coordinator.waitUntilIdle()
    }

    @Test func distinctWorkflowsAreNotCooledDown() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)

        #expect(await coordinator.submit(workflow("A"), source: .automatic(.schedule)) == .started)
        #expect(await coordinator.submit(workflow("B"), source: .automatic(.schedule)) == .queued)
        await coordinator.waitUntilIdle()
    }

    @Test func queueLimitIsTenQueuedRuns() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)

        #expect(await coordinator.submit(workflow("running"), source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)

        for index in 0..<10 {
            #expect(await coordinator.submit(workflow("queued-\(index)"), source: .automatic(.schedule)) == .queued)
        }
        #expect(await coordinator.status().queuedCount == 10)
        #expect(await coordinator.submit(workflow("overflow"), source: .automatic(.schedule)) == .queueFull)

        probe.open()
        await coordinator.waitUntilIdle()
    }

    @Test func queuedAutomaticRunExpires() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .queued)

        clock.advance(by: .seconds(31))
        probe.open()
        await coordinator.waitUntilIdle()

        #expect(probe.started == [first.id])
        let events = await coordinator.status().recentEvents
        #expect(events.contains { $0.kind == .expired && $0.automationID == second.id })
    }

    @Test func manualRunsDoNotExpire() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .manual) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .manual) == .queued)

        clock.advance(by: .seconds(31))
        probe.open()
        await coordinator.waitUntilIdle()

        #expect(probe.started == [first.id, second.id])
    }

    @Test func pauseClearsPendingAutomaticButLetsCurrentFinish() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .queued)

        await coordinator.pauseAutomaticTriggers()
        #expect(await coordinator.status().isPaused)
        #expect(await coordinator.status().queuedCount == 0)
        let events = await coordinator.status().recentEvents
        #expect(events.contains { $0.kind == .pausedCleared && $0.automationID == second.id })

        probe.open()
        await coordinator.waitUntilIdle()
        #expect(probe.started == [first.id])
    }

    @Test func pauseSuppressesAutomaticButAllowsManual() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)

        await coordinator.pauseAutomaticTriggers()
        #expect(await coordinator.submit(workflow(), source: .automatic(.schedule)) == .suppressedPaused)
        #expect(await coordinator.submit(workflow(), source: .manual) == .started)
        await coordinator.waitUntilIdle()
    }

    @Test func resumeAllowsAutomaticAgain() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow()

        await coordinator.pauseAutomaticTriggers()
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .suppressedPaused)
        await coordinator.resumeAutomaticTriggers()
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await coordinator.waitUntilIdle()
    }

    @Test func sessionNotReadySuppressesAutomaticAndInterruptsActive() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .queued)

        await coordinator.updateSessionReadiness(false)
        #expect(await coordinator.status().queuedCount == 0)
        let events = await coordinator.status().recentEvents
        #expect(events.contains { $0.kind == .sleepInterrupted && $0.automationID == second.id })
        #expect(await coordinator.submit(workflow("Third"), source: .automatic(.schedule)) == .suppressedSessionNotReady)

        probe.open()
        await coordinator.waitUntilIdle()
        #expect(probe.started == [first.id])
    }

    @Test func cancelAllClearsQueue() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .automatic(.schedule)) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .automatic(.schedule)) == .queued)

        await coordinator.cancelAll()
        #expect(await coordinator.status().queuedCount == 0)
        await coordinator.waitUntilIdle()
        #expect(probe.started == [first.id])
    }

    @Test func runsExecuteInOrderOneAtATime() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")
        let third = workflow("Third")

        #expect(await coordinator.submit(first, source: .manual) == .started)
        await probe.awaitStarted(1)
        #expect(await coordinator.submit(second, source: .manual) == .queued)
        #expect(await coordinator.submit(third, source: .manual) == .queued)

        probe.open()
        await coordinator.waitUntilIdle()
        #expect(probe.started == [first.id, second.id, third.id])
    }

    @Test func invalidDefinitionIsRejected() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let invalid = AutomationDefinition(
            name: "   ",
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )

        if case .rejected = await coordinator.submit(invalid, source: .manual) {
            // expected
        } else {
            Issue.record("Expected an invalid definition to be rejected")
        }
        #expect(probe.started.isEmpty)
    }

    @Test func eventLogIsBounded() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe, maximumEventLog: 1)
        let definition = workflow()

        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .started)
        await coordinator.waitUntilIdle()
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .suppressedCooldown)
        clock.advance(by: .seconds(1))
        #expect(await coordinator.submit(definition, source: .automatic(.schedule)) == .suppressedCooldown)

        #expect(await coordinator.status().recentEvents.count == 1)
    }

    @Test func statusReportsCurrentRun() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow("Named")

        #expect(await coordinator.submit(definition, source: .manual) == .started)
        await probe.awaitStarted(1)

        let status = await coordinator.status()
        #expect(status.isRunning)
        #expect(status.currentName == "Named")

        probe.open()
        await coordinator.waitUntilIdle()
        #expect(!(await coordinator.status().isRunning))
    }

    @Test func submitAndWaitReturnsTheRecord() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let definition = workflow("Await")

        let record = await coordinator.submitAndWait(definition, source: .manual)
        #expect(record?.status == .succeeded)
        #expect(record?.automationID == definition.id)
        #expect(probe.started == [definition.id])
    }

    @Test func submitAndWaitQueuesBehindActiveRun() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .manual) == .started)
        await probe.awaitStarted(1)

        let secondTask = Task { await coordinator.submitAndWait(second, source: .manual) }
        while await coordinator.status().queuedCount == 0 {
            await Task.yield()
        }

        probe.open()
        let record = await secondTask.value
        #expect(record?.automationID == second.id)
        #expect(record?.status == .succeeded)
        #expect(probe.started == [first.id, second.id])
    }

    @Test func cancelAllResumesQueuedWaiterAsCancelled() async {
        let clock = TestClock()
        let probe = ExecutionProbe()
        probe.blocking = true
        let coordinator = makeCoordinator(clock: clock, probe: probe)
        let first = workflow("First")
        let second = workflow("Second")

        #expect(await coordinator.submit(first, source: .manual) == .started)
        await probe.awaitStarted(1)

        let secondTask = Task { await coordinator.submitAndWait(second, source: .manual) }
        while await coordinator.status().queuedCount == 0 {
            await Task.yield()
        }

        await coordinator.cancelAll()
        let record = await secondTask.value
        #expect(record?.status == .cancelled)
        #expect(record?.automationID == second.id)

        probe.open()
        await coordinator.waitUntilIdle()
    }
}
