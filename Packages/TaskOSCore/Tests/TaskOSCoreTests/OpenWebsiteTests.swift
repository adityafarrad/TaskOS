import Testing
import Foundation
@testable import TaskOSCore

private struct EmptyCatalog: ResourceCatalog {
    func application(bundleIdentifier: String) async -> ApplicationResource? { nil }
}

private struct GrantedPermissions: PermissionStatusProvider {
    func state(for permission: PermissionKind) async -> PermissionState { .granted }
}

@Suite("Open website")
struct OpenWebsiteTests {
    @Test func validationAcceptsOnlyAbsoluteHTTPURLs() {
        #expect(OpenWebsiteAction(url: "https://example.com").validate().isValid)
        #expect(OpenWebsiteAction(url: "http://example.com/path?q=1").validate().isValid)
        #expect(!OpenWebsiteAction(url: "example.com").validate().isValid)
        #expect(!OpenWebsiteAction(url: "ftp://example.com").validate().isValid)
        #expect(!OpenWebsiteAction(url: "").validate().isValid)
    }

    @Test func heuristicsClassifyWebsitesVersusApplications() {
        #expect(ResourceNameHeuristics.isWebsite("apple.com"))
        #expect(ResourceNameHeuristics.isWebsite("https://apple.com/path"))
        #expect(ResourceNameHeuristics.isWebsite("example.co.uk"))
        #expect(!ResourceNameHeuristics.isWebsite("Safari"))
        #expect(!ResourceNameHeuristics.isWebsite("Google Chrome"))
        #expect(ResourceNameHeuristics.normalizedWebsiteURL("apple.com") == "https://apple.com")
        #expect(ResourceNameHeuristics.normalizedWebsiteURL("http://apple.com") == "http://apple.com")
    }

    @Test func bareDomainRequiresExplicitAcceptance() {
        var document = ComposerDocument()
        document.setText("open apple.com")

        #expect(document.actions.count == 1)
        guard case .openWebsite(let url, _) = document.actions[0].draft else {
            Issue.record("Expected a website draft")
            return
        }
        #expect(url == "apple.com")
        #expect(document.hasUnresolvedWebsites)
        #expect(document.makeDefinition(name: "Test") == nil)

        document.setText("open https://apple.com")
        #expect(!document.hasUnresolvedWebsites)
        #expect(document.makeDefinition(name: "Test") != nil)
    }

    @Test func placeholderWebsiteBlocksUntilValid() {
        var document = ComposerDocument()
        document.addAction(.openWebsite(url: "https://", browser: nil))

        #expect(document.hasUnresolvedWebsites)

        document.updateAction(id: document.actions[0].id, draft: .openWebsite(url: "https://example.com", browser: nil))

        #expect(!document.hasUnresolvedWebsites)
    }

    @Test func canonicalPhraseRoundTripsAWebsite() {
        let action = ActionConfiguration.openWebsite(OpenWebsiteAction(url: "https://example.com"))
        #expect(CanonicalPhrase.text(for: action) == "Open https://example.com")

        let parsed = CommandParser().parse(CanonicalPhrase.command(for: [action]))
        #expect(parsed.outcome == .complete)
    }

    @Test func previewMarksValidWebsiteReady() async {
        let preparer = CreationPreparer(catalog: EmptyCatalog(), permissions: GrantedPermissions())
        let definition = AutomationDefinition(
            name: "Site",
            trigger: .manual(ManualTrigger()),
            actions: [.openWebsite(OpenWebsiteAction(url: "https://example.com"))]
        )

        let preview = await preparer.prepare(definition)
        #expect(preview.actions.first?.status == .ready)
        #expect(preview.isRunnable)
    }

    @Test func emptyFieldSuggestsWebsite() {
        let suggestions = SuggestionEngine().suggestions(for: "")
        #expect(suggestions.contains { $0.id == "action.openWebsite" })
    }

    @Test func selectedBrowserFlowsIntoResolvedAction() {
        var document = ComposerDocument()
        document.setText("open https://apple.com")

        document.setWebsiteBrowser(
            id: document.actions[0].id,
            browser: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )

        let actions = document.resolvedActions()
        #expect(actions?.count == 1)
        guard case .openWebsite(let action)? = actions?.first else {
            Issue.record("Expected an open website action")
            return
        }
        #expect(action.browser?.identifier == "com.apple.Safari")
    }

    @Test func previewReportsMissingBrowser() async {
        let preparer = CreationPreparer(catalog: EmptyCatalog(), permissions: GrantedPermissions())
        let definition = AutomationDefinition(
            name: "Site",
            trigger: .manual(ManualTrigger()),
            actions: [
                .openWebsite(
                    OpenWebsiteAction(
                        url: "https://example.com",
                        browser: .application(bundleIdentifier: "com.brave.Browser", label: "Brave")
                    )
                )
            ]
        )

        let preview = await preparer.prepare(definition)
        #expect(!preview.isValid)
        #expect(preview.actions[0].status == .missingResource)
    }
}
