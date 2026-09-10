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

    private let catalog: WorkspaceResourceCatalog

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
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
