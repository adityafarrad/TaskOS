import Foundation
import TaskOSCore

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner
    let preparer: CreationPreparer
    let approvals: ApprovalRegistry
    let suggestions: SuggestionEngine
    let repository: FileAutomationRepository

    private let catalog: WorkspaceResourceCatalog

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        let supportDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        let workflowDirectory = supportDirectory
            .appendingPathComponent("TaskOS", isDirectory: true)
            .appendingPathComponent("Workflows", isDirectory: true)

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
        self.repository = FileAutomationRepository(directory: workflowDirectory)
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: SystemPermissionStatusProvider()
        )
        self.runner = WorkflowRunner(
            clock: clock,
            executors: [
                OpenApplicationExecutor(),
                NotificationExecutor(),
            ]
        )
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }
}
