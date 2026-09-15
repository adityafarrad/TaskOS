import Testing
import Foundation
@testable import TaskOSCore

@Suite("Workflow portability")
struct PortabilityTests {
    private func sampleDefinition() -> AutomationDefinition {
        AutomationDefinition(
            name: "Morning routine",
            trigger: .schedule(.weekdays([.monday, .friday], hour: 9, minute: 0)),
            actions: [
                .openApplication(OpenApplicationAction(application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari"))),
                .openWebsite(OpenWebsiteAction(url: "https://example.com", browser: .application(bundleIdentifier: "com.apple.Safari", label: "Safari"))),
                .wait(WaitAction(duration: 2)),
                .showNotification(ShowNotificationAction(title: "Ready", message: "All set")),
                .copyText(CopyTextAction(text: "agenda")),
            ]
        )
    }

    @Test func roundTripPreservesTriggerOrderAndLiterals() throws {
        let original = sampleDefinition()
        let data = try WorkflowPortability.export(original)
        let imported = try WorkflowPortability.importWorkflow(data)

        #expect(imported.name == original.name)
        #expect(imported.trigger == original.trigger)
        #expect(imported.actions.map(\.id) == original.actions.map(\.id))

        if case .openWebsite(let website)? = imported.actions.first(where: { $0.id == .openWebsite }) {
            #expect(website.url == "https://example.com")
        } else {
            Issue.record("Expected the website action")
        }
        if case .showNotification(let notification)? = imported.actions.first(where: { $0.id == .showNotification }) {
            #expect(notification.title == "Ready")
            #expect(notification.message == "All set")
        }
        if case .copyText(let copy)? = imported.actions.first(where: { $0.id == .copyText }) {
            #expect(copy.text == "agenda")
        } else {
            Issue.record("Expected the copy action")
        }
    }

    @Test func importedResourcesRequireRebinding() throws {
        let data = try WorkflowPortability.export(sampleDefinition())
        let imported = try WorkflowPortability.importWorkflow(data)

        if case .openApplication(let action)? = imported.actions.first(where: { $0.id == .openApplication }) {
            #expect(action.application.label == "Safari")
            #expect(action.application.identifier.isEmpty)
        } else {
            Issue.record("Expected the application action")
        }

        // Unresolved resources keep the workflow from being runnable before review.
        #expect(!imported.validate().isValid)
    }

    @Test func fileReferencesDropLocalAuthority() throws {
        let definition = AutomationDefinition(
            name: "Files",
            trigger: .manual(ManualTrigger()),
            actions: [
                .openFile(OpenFileAction(target: FileTarget(kind: .file, displayName: "report.pdf", path: "/Users/me/report.pdf", bookmark: Data([1, 2, 3])))),
            ]
        )
        let data = try WorkflowPortability.export(definition)
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("/Users/me/report.pdf"))

        let imported = try WorkflowPortability.importWorkflow(data)
        if case .openFile(let action)? = imported.actions.first {
            #expect(action.target.displayName == "report.pdf")
            #expect(action.target.path.isEmpty)
            #expect(action.target.bookmark == nil)
        } else {
            Issue.record("Expected the file action")
        }
    }

    @Test func importedSpecificDisplayBecomesCurrent() throws {
        let definition = AutomationDefinition(
            name: "Display",
            trigger: .manual(ManualTrigger()),
            actions: [
                .arrangeWindow(
                    ArrangeWindowAction(
                        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari"),
                        preset: .leftHalf,
                        display: .display(identifier: "42")
                    )
                ),
            ]
        )
        let data = try WorkflowPortability.export(definition)
        let imported = try WorkflowPortability.importWorkflow(data)

        if case .arrangeWindow(let action)? = imported.actions.first {
            #expect(action.display == .current)
        } else {
            Issue.record("Expected an arrange window action")
        }
    }

    @Test func freshIdentityIsAssigned() throws {
        let data = try WorkflowPortability.export(sampleDefinition())
        let id = AutomationID()
        let imported = try WorkflowPortability.importWorkflow(data, id: id)
        #expect(imported.id == id)
        #expect(imported.revision == WorkflowRevision(1))
    }

    @Test func futureFormatIsRejected() throws {
        let json = #"{"formatVersion":999,"name":"X","trigger":{"manual":{"_0":{}}},"actions":[]}"#
        #expect(throws: PortabilityError.unsupportedFormat(found: 999, supported: 1)) {
            try WorkflowPortability.importWorkflow(Data(json.utf8))
        }
    }

    @Test func oversizedImportIsRejected() throws {
        #expect(throws: PortabilityError.tooLarge) {
            try WorkflowPortability.importWorkflow(Data(count: WorkflowPortability.maximumBytes + 1))
        }
    }

    @Test func unknownActionFieldsAreRejected() throws {
        let json = #"{"formatVersion":1,"name":"X","trigger":{"manual":{"_0":{}}},"actions":[{"explode":{}}]}"#
        var rejected = false
        do {
            _ = try WorkflowPortability.importWorkflow(Data(json.utf8))
        } catch {
            rejected = true
        }
        #expect(rejected)
    }

    @Test func oversizedExportIsRejected() throws {
        let text = String(repeating: "a", count: 25_000)
        let action = ActionConfiguration.copyText(CopyTextAction(text: text))
        let definition = AutomationDefinition(
            name: "Huge",
            trigger: .manual(ManualTrigger()),
            actions: Array(repeating: action, count: 12)
        )
        #expect(throws: PortabilityError.tooLarge) {
            _ = try WorkflowPortability.export(definition)
        }
    }

    @Test func oversizedFileOnDiskIsRejectedBeforeParsing() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data(count: WorkflowPortability.maximumBytes + 1).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: PortabilityError.tooLarge) {
            _ = try WorkflowPortability.importWorkflow(at: url)
        }
    }
}
