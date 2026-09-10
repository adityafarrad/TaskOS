import Foundation
import SwiftData
import TaskOSCore

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner
    let preparer: CreationPreparer
    let approvals: ApprovalRegistry
    let suggestions: SuggestionEngine
    let repository: any AutomationRepository

    private let catalog: WorkspaceResourceCatalog

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        let container: ModelContainer
        do {
            container = try ModelContainer(for: WorkflowRecord.self)
        } catch {
            container = try! ModelContainer(
                for: WorkflowRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
        self.repository = SwiftDataAutomationRepository(modelContainer: container)
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: SystemPermissionStatusProvider()
        )
        self.runner = WorkflowRunner(
            clock: clock,
            executors: [
                OpenApplicationExecutor(),
                OpenWebsiteExecutor(),
                NotificationExecutor(),
            ]
        )
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }
}
