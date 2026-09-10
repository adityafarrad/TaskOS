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
    let runHistory: any RunHistoryRepository

    private let catalog: WorkspaceResourceCatalog

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        let container: ModelContainer
        do {
            container = try ModelContainer(for: WorkflowRecord.self, RunRecordEntry.self)
        } catch {
            container = try! ModelContainer(
                for: WorkflowRecord.self,
                RunRecordEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
        self.repository = SwiftDataAutomationRepository(modelContainer: container)
        self.runHistory = SwiftDataRunHistoryRepository(modelContainer: container)
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: SystemPermissionStatusProvider()
        )
        self.runner = WorkflowRunner(
            clock: clock,
            executors: [
                OpenApplicationExecutor(),
                OpenWebsiteExecutor(),
                ArrangeWindowExecutor(),
                NotificationExecutor(),
            ]
        )
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }
}
