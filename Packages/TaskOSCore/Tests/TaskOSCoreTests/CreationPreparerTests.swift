import Testing
import Foundation
@testable import TaskOSCore

private struct FakeCatalog: ResourceCatalog {
    var installed: [String: ApplicationResource]

    func application(bundleIdentifier: String) async -> ApplicationResource? {
        installed[bundleIdentifier]
    }
}

private struct FakePermissions: PermissionStatusProvider {
    var states: [PermissionKind: PermissionState]

    func state(for permission: PermissionKind) async -> PermissionState {
        states[permission] ?? .notDetermined
    }
}

private func makeDefinition(_ actions: [ActionConfiguration]) -> AutomationDefinition {
    AutomationDefinition(
        name: "Preview test",
        revision: WorkflowRevision(4),
        trigger: .manual(ManualTrigger()),
        actions: actions
    )
}

private let openSafari = ActionConfiguration.openApplication(
    OpenApplicationAction(
        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
    )
)

private let showNotification = ActionConfiguration.showNotification(
    ShowNotificationAction(title: "Done", message: "Finished")
)

@Suite("Creation preparer")
struct CreationPreparerTests {
    private func preparer(
        installed: [String: ApplicationResource],
        permission: PermissionState
    ) -> CreationPreparer {
        CreationPreparer(
            catalog: FakeCatalog(installed: installed),
            permissions: FakePermissions(states: [.notifications: permission])
        )
    }

    @Test func resolvesInstalledApplication() async {
        let subject = preparer(
            installed: ["com.apple.Safari": ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari")],
            permission: .granted
        )
        let preview = await subject.prepare(makeDefinition([openSafari]))

        #expect(preview.actions.count == 1)
        #expect(preview.actions[0].status == .ready)
        #expect(preview.actions[0].targetLabel == "Safari")
        #expect(preview.isRunnable)
        #expect(preview.revision == WorkflowRevision(4))
    }

    @Test func missingApplicationBlocksRun() async {
        let subject = preparer(installed: [:], permission: .granted)
        let preview = await subject.prepare(makeDefinition([openSafari]))

        #expect(preview.actions[0].status == .missingResource)
        #expect(!preview.isValid)
        #expect(!preview.isRunnable)
        #expect(!preview.issues.isEmpty)
    }

    @Test func undeterminedNotificationPermissionIsRunnable() async {
        let subject = preparer(installed: [:], permission: .notDetermined)
        let preview = await subject.prepare(makeDefinition([showNotification]))

        #expect(preview.actions[0].status == .needsPermission)
        #expect(preview.isValid)
        #expect(preview.isRunnable)
        #expect(preview.requiredPermissions == [.notifications])
    }

    @Test func deniedNotificationPermissionBlocksRun() async {
        let subject = preparer(installed: [:], permission: .denied)
        let preview = await subject.prepare(makeDefinition([showNotification]))

        #expect(preview.actions[0].status == .needsPermission)
        #expect(!preview.isValid)
        #expect(!preview.isRunnable)
    }

    @Test func previewNeverReportsAutomaticRunsForManualTrigger() async {
        let subject = preparer(installed: [:], permission: .granted)
        let preview = await subject.prepare(makeDefinition([openSafari, .wait(WaitAction(duration: 1))]))

        #expect(preview.triggerTitle == "Manual")
        #expect(preview.willRunAutomatically == false)
        #expect(preview.actions.map(\.actionID) == [.openApplication, .wait])
    }
}
