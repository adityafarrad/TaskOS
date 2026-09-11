import Testing
import Foundation
import TaskOSCore

@Suite("Composer definition mapping")
struct DefinitionMappingTests {
    private let safari = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")

    @Test func editingPreservesCardOnlyValues() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let future = now.addingTimeInterval(86_400)

        let definition = AutomationDefinition(
            name: "Edit",
            revision: WorkflowRevision(3),
            trigger: .schedule(.oneTime(future)),
            actions: [
                .openWebsite(OpenWebsiteAction(url: "https://example.com", browser: safari)),
                .showNotification(ShowNotificationAction(title: "Custom title", message: "Custom message")),
                .openFile(OpenFileAction(target: FileTarget(kind: .file, displayName: "report.pdf", path: "/tmp/report.pdf"))),
                .arrangeWindow(ArrangeWindowAction(application: safari, preset: .topRightQuarter, display: .display(identifier: "42"))),
            ]
        )

        let document = ComposerDocument(definition: definition)
        let rebuilt = document.makeDefinition(
            name: "Edit",
            id: definition.id,
            revision: definition.revision,
            now: now
        )

        #expect(rebuilt?.trigger == definition.trigger)
        #expect(rebuilt?.actions == definition.actions)
    }

    @Test func editingPreservesIntervalDuration() {
        let definition = AutomationDefinition(
            name: "Interval",
            trigger: .schedule(.interval(every: 900, startingAt: Date())),
            actions: [.wait(WaitAction(duration: 1))]
        )
        let document = ComposerDocument(definition: definition)
        if case .interval(let every) = document.trigger {
            #expect(every == 900)
        } else {
            Issue.record("Expected an interval trigger")
        }
    }

    @Test func editingPreservesEventTrigger() {
        let definition = AutomationDefinition(
            name: "Display",
            trigger: .displayConnection(DisplayConnectionTrigger(selection: .anyExternal, event: .connected)),
            actions: [.wait(WaitAction(duration: 1))]
        )
        let document = ComposerDocument(definition: definition)
        #expect(document.trigger == .displayConnection(event: .connected, selection: .anyExternal))
    }

    @Test func importedDefinitionShowsUnresolvedResources() {
        let definition = AutomationDefinition(
            name: "Imported",
            trigger: .manual(ManualTrigger()),
            actions: [
                .openApplication(OpenApplicationAction(application: .application(bundleIdentifier: "", label: "Safari"))),
                .openFile(OpenFileAction(target: FileTarget(kind: .file, displayName: "notes.txt", path: ""))),
            ]
        )
        let document = ComposerDocument(definition: definition)

        #expect(document.hasUnresolvedActions)
        #expect(document.makeDefinition(name: "Imported") == nil)
    }
}
