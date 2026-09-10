import Foundation
import SwiftData
import TaskOSCore

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner
    let coordinator: RunCoordinator
    let preparer: CreationPreparer
    let approvals: ApprovalRegistry
    let suggestions: SuggestionEngine
    let repository: any AutomationRepository
    let runHistory: any RunHistoryRepository
    let drafts: any DraftRepository
    let permissions: any PermissionStatusProvider

    private let catalog: WorkspaceResourceCatalog
    private let sessionObserver: SystemSessionObserver

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        let container: ModelContainer
        do {
            container = try ModelContainer(for: WorkflowRecord.self, RunRecordEntry.self, DraftRecord.self)
        } catch {
            container = try! ModelContainer(
                for: WorkflowRecord.self,
                RunRecordEntry.self,
                DraftRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let runHistory = SwiftDataRunHistoryRepository(modelContainer: container)
        let runner = WorkflowRunner(
            clock: clock,
            executors: [
                OpenApplicationExecutor(),
                OpenWebsiteExecutor(),
                ArrangeWindowExecutor(),
                NotificationExecutor(),
            ]
        )

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
        self.repository = SwiftDataAutomationRepository(modelContainer: container)
        self.runHistory = runHistory
        self.drafts = SwiftDataDraftRepository(modelContainer: container)
        let permissions = SystemPermissionStatusProvider()
        self.permissions = permissions
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: permissions
        )
        self.runner = runner
        let coordinator = RunCoordinator(clock: clock) { definition, id in
            try? await runHistory.append(RunRecord.starting(definition, id: id))
            await MainActor.run {
                NotificationCenter.default.post(name: .taskOSRunHistoryDidChange, object: nil)
            }
            let record = await runner.run(definition, id: id)
            try? await runHistory.update(record)
            await MainActor.run {
                NotificationCenter.default.post(name: .taskOSRunHistoryDidChange, object: nil)
            }
            return record
        }
        self.coordinator = coordinator
        self.sessionObserver = SystemSessionObserver(coordinator: coordinator)
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }
}

extension Notification.Name {
    static let taskOSRunHistoryDidChange = Notification.Name("taskOSRunHistoryDidChange")
}
