import Foundation
import Testing
import TaskOSCore
@testable import TaskOS

@MainActor
@Suite("Run result presentation")
struct RunPresentationTests {
    private func makeRecord(
        status: RunStatus,
        outcomes: [ActionOutcome],
        actionIDs: [ActionID]? = nil
    ) -> RunRecord {
        let ids = actionIDs ?? outcomes.map { _ in ActionID.wait }
        let actions = zip(ids, outcomes).enumerated().map { index, pair in
            ActionRunRecord(index: index, actionID: pair.0, outcome: pair.1, duration: 0.2)
        }
        return RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Test",
            status: status,
            startedAt: Date(timeIntervalSince1970: 0),
            finishedAt: Date(timeIntervalSince1970: 1),
            actions: actions
        )
    }

    @Test func successSummaryCountsAllSteps() {
        let record = makeRecord(status: .succeeded, outcomes: [.succeeded, .succeeded])
        #expect(RunPresentation.summary(for: record) == "All 2 steps completed.")

        let single = makeRecord(status: .succeeded, outcomes: [.succeeded])
        #expect(RunPresentation.summary(for: single) == "The step completed.")
    }

    @Test func failureSummaryNamesStepAndReason() {
        let record = makeRecord(
            status: .failed,
            outcomes: [.succeeded, .failed(ActionFailure(message: "Safari is not running.")), .notExecuted]
        )
        let summary = RunPresentation.summary(for: record)
        #expect(summary == "Completed 1 of 3 steps. Step 2 failed: Safari is not running.")
    }

    @Test func cancellationExplainsPartialCompletion() {
        let record = makeRecord(status: .cancelled, outcomes: [.succeeded, .cancelled, .notExecuted])
        let summary = RunPresentation.summary(for: record)
        #expect(summary == "Stopped after 1 of 3 steps. Steps already completed are not undone.")
    }

    @Test func interruptionExplainsPartialCompletion() {
        let record = makeRecord(status: .interrupted, outcomes: [.succeeded, .notExecuted])
        let summary = RunPresentation.summary(for: record)
        #expect(summary == "Interrupted after 1 of 2 steps. Steps already completed are not undone.")
    }

    @Test func timeoutSummaryCountsCompleted() {
        let record = makeRecord(status: .timedOut, outcomes: [.succeeded, .failed(ActionFailure(message: "timed out", isTimedOut: true))])
        #expect(RunPresentation.summary(for: record) == "Timed out after 1 of 2 steps.")
    }

    @Test func permissionFixDetectsNotificationAndAccessibility() {
        let notification = makeRecord(
            status: .failed,
            outcomes: [.failed(ActionFailure(message: "Notification permission is off."))],
            actionIDs: [.showNotification]
        )
        #expect(RunPresentation.permissionFix(for: notification) == .notifications)

        let accessibility = makeRecord(
            status: .failed,
            outcomes: [.failed(ActionFailure(message: "Accessibility access is required."))],
            actionIDs: [.arrangeWindow]
        )
        #expect(RunPresentation.permissionFix(for: accessibility) == .accessibility)

        let unrelated = makeRecord(status: .failed, outcomes: [.failed(ActionFailure(message: "Could not open."))])
        #expect(RunPresentation.permissionFix(for: unrelated) == nil)
    }
}
