import Foundation
import TaskOSCore

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner

    init() {
        let clock = SystemClock()
        let executors: [any ActionExecutor] = [
            OpenApplicationExecutor(),
            NotificationExecutor(),
        ]
        self.clock = clock
        self.runner = WorkflowRunner(clock: clock, executors: executors)
    }

    func walkingSliceDefinition() -> AutomationDefinition {
        AutomationDefinition(
            name: "Walking slice",
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
