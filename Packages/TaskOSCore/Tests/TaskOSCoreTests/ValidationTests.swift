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
}
