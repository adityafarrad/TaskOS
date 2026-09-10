import Foundation
import TaskOSCore

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner
    let preparer: CreationPreparer
    let approvals: ApprovalRegistry

    init() {
        let clock = SystemClock()
        self.clock = clock
        self.approvals = ApprovalRegistry()
        self.preparer = CreationPreparer(
            catalog: WorkspaceResourceCatalog(),
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

    func initialDefinition() -> AutomationDefinition {
        AutomationDefinition(
            name: "Walking slice",
            revision: WorkflowRevision(1),
            trigger: .manual(ManualTrigger()),
            actions: [
                .openApplication(
                    OpenApplicationAction(
                        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
                    )
                ),
                .wait(WaitAction(duration: 1)),
                .showNotification(
                    ShowNotificationAction(title: "TaskOS", message: "Safari is open.")
                ),
            ]
        )
    }
}
