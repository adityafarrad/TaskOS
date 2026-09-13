import Testing
import Foundation
import SwiftData
import TaskOSCore
@testable import TaskOS

private actor ExecutionLog {
    private var actions: [ActionID] = []

    func record(_ id: ActionID) {
        actions.append(id)
    }

    func all() -> [ActionID] {
        actions
    }
}

private struct RecordingExecutor: ActionExecutor {
    let supportedID: ActionID
    let log: ExecutionLog

    func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        await log.record(supportedID)
        return .succeeded
    }
}

@Suite("Saved workflow execution without the parser", .serialized)
struct SavedWorkflowRunTests {
    @Test func savedWorkflowLoadsAndRunsWithoutParser() async throws {
        let container = try ModelContainer(
            for: WorkflowRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataAutomationRepository(modelContainer: container)

        let definition = AutomationDefinition(
            name: "No parser",
            trigger: .manual(ManualTrigger()),
            actions: [
                .openApplication(
                    OpenApplicationAction(
                        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
                    )
                ),
                .wait(WaitAction(duration: 0.1)),
            ]
        )
        try await repository.save(SavedWorkflow(definition: definition))

        let loaded = try await repository.loadAll()
        let workflow = try #require(loaded.first)

        let log = ExecutionLog()
        let runner = WorkflowRunner(
            clock: SystemClock(),
            executors: [RecordingExecutor(supportedID: .openApplication, log: log)]
        )
        let record = await runner.run(workflow.definition)

        #expect(record.status == .succeeded)
        #expect(record.actions.map(\.actionID) == [.openApplication, .wait])
        #expect(await log.all() == [.openApplication])
    }
}
