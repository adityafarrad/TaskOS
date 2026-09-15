import Testing
import Foundation
import TaskOSCore

@Suite("Validation")
struct ValidationTests {
    @Test func waitAcceptsBoundsAndRejectsOutside() {
        #expect(WaitAction(duration: 0.1).validate().isValid)
        #expect(WaitAction(duration: 30.0).validate().isValid)
        #expect(!WaitAction(duration: 0.05).validate().isValid)
        #expect(!WaitAction(duration: 31.0).validate().isValid)
    }

    @Test func openApplicationRequiresApplicationResource() {
        let good = OpenApplicationAction(
            application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )
        #expect(good.validate().isValid)

        let wrongKind = OpenApplicationAction(
            application: ResourceReference(kind: .website, identifier: "https://example.com", label: "Example")
        )
        #expect(!wrongKind.validate().isValid)
    }

    @Test func openApplicationRejectsEmptyIdentifier() {
        let action = OpenApplicationAction(
            application: ResourceReference(kind: .application, identifier: " ", label: "Safari")
        )
        #expect(!action.validate().isValid)
    }

    @Test func notificationRequiresTitleButEmptyMessageIsOnlyAWarning() {
        #expect(ShowNotificationAction(title: "Hello", message: "World").validate().isValid)

        let noTitle = ShowNotificationAction(title: "  ", message: "World").validate()
        #expect(!noTitle.isValid)

        let noMessage = ShowNotificationAction(title: "Hello", message: "").validate()
        #expect(noMessage.isValid)
        #expect(noMessage.issues.contains { $0.severity == .warning })
    }

    @Test func notificationFieldsAreBounded() {
        let longTitle = String(repeating: "T", count: ShowNotificationAction.maximumTitleLength + 1)
        let longMessage = String(repeating: "M", count: ShowNotificationAction.maximumMessageLength + 1)

        #expect(!ShowNotificationAction(title: longTitle, message: "ok").validate().isValid)
        #expect(!ShowNotificationAction(title: "ok", message: longMessage).validate().isValid)
        #expect(ShowNotificationAction(title: String(repeating: "T", count: ShowNotificationAction.maximumTitleLength), message: "ok").validate().isValid)
    }

    @Test func workflowNameIsBounded() {
        let longName = String(repeating: "n", count: AutomationDefinition.maximumNameLength + 1)
        let definition = AutomationDefinition(
            name: longName,
            trigger: .manual(ManualTrigger()),
            actions: [.wait(WaitAction(duration: 1))]
        )
        #expect(!definition.validate().isValid)
    }
}
