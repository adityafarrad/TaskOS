import Testing
import Foundation
import TaskOSCore

@Suite("Hide and quit application")
struct HideQuitTests {
    private let parser = CommandParser()
    private let safari = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")

    @Test func parsesHide() {
        let parsed = parser.parse("hide Safari")
        #expect(parsed.outcome == .complete)
        let clause = parsed.clauses.first { $0.kind == .hideApplication }
        #expect(clause?.resourceNames == ["Safari"])
    }

    @Test func parsesQuitList() {
        let parsed = parser.parse("quit Safari and Notes")
        let clause = parsed.clauses.first { $0.kind == .quitApplication }
        #expect(clause?.resourceNames == ["Safari", "Notes"])
    }

    @Test func missingApplicationNeedsInput() {
        #expect(parser.parse("hide").outcome == .needsInput)
        #expect(parser.parse("quit").outcome == .needsInput)
    }

    @Test func canonicalPhrasesRoundTrip() {
        let hide = ActionConfiguration.hideApplication(HideApplicationAction(application: safari))
        let quit = ActionConfiguration.quitApplication(QuitApplicationAction(application: safari))

        #expect(CanonicalPhrase.text(for: hide) == "Hide Safari")
        #expect(CanonicalPhrase.text(for: quit) == "Quit Safari")

        #expect(parser.parse(CanonicalPhrase.text(for: hide)).clauses.first { $0.kind == .hideApplication }?.resourceNames == ["Safari"])
        #expect(parser.parse(CanonicalPhrase.text(for: quit)).clauses.first { $0.kind == .quitApplication }?.resourceNames == ["Safari"])
    }

    @Test func composerBuildsHideDefinition() {
        var document = ComposerDocument(text: "hide Safari")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected an action")
            return
        }
        document.resolveApplication(id: id, reference: safari)
        let definition = document.makeDefinition(name: "Hide")
        if case .hideApplication(let action)? = definition?.actions.first {
            #expect(action.application == safari)
        } else {
            Issue.record("Expected a hide action")
        }
    }

    @Test func quitRejectsProtectedApplications() {
        let protected = QuitApplicationAction(
            application: .application(bundleIdentifier: "com.apple.finder", label: "Finder")
        )
        #expect(!protected.validate().isValid)

        let taskOS = QuitApplicationAction(
            application: .application(bundleIdentifier: "usuals.com.TaskOS", label: "TaskOS")
        )
        #expect(!taskOS.validate().isValid)

        #expect(QuitApplicationAction(application: safari).validate().isValid)
    }

    @Test func hideRequiresResolvedApplication() {
        #expect(!HideApplicationAction(application: .application(bundleIdentifier: "", label: "")).validate().isValid)
        #expect(HideApplicationAction(application: safari).validate().isValid)
    }

    @Test func hideAndQuitRequireNoPermissions() {
        #expect(ActionConfiguration.hideApplication(HideApplicationAction(application: safari)).requiredPermissions.isEmpty)
        #expect(ActionConfiguration.quitApplication(QuitApplicationAction(application: safari)).requiredPermissions.isEmpty)
    }
}
