import Testing
import Foundation
@testable import TaskOSCore

private struct ArrangeCatalog: ResourceCatalog {
    var installed: [String: ApplicationResource]

    func application(bundleIdentifier: String) async -> ApplicationResource? {
        installed[bundleIdentifier]
    }
}

private struct StubPermissions: PermissionStatusProvider {
    var accessibility: PermissionState

    func state(for permission: PermissionKind) async -> PermissionState {
        switch permission {
        case .accessibility: return accessibility
        case .notifications: return .granted
        }
    }
}

private func safariReference() -> ResourceReference {
    .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
}

@Suite("Window presets")
struct WindowPresetTests {
    private let usable = WindowFrame(x: 0, y: 0, width: 1000, height: 800)
    private let current = WindowFrame(x: 100, y: 100, width: 400, height: 300)

    @Test func halvesAndQuarters() {
        #expect(WindowPreset.leftHalf.targetFrame(in: usable, currentSize: current) == WindowFrame(x: 0, y: 0, width: 500, height: 800))
        #expect(WindowPreset.rightHalf.targetFrame(in: usable, currentSize: current) == WindowFrame(x: 500, y: 0, width: 500, height: 800))
        #expect(WindowPreset.bottomHalf.targetFrame(in: usable, currentSize: current) == WindowFrame(x: 0, y: 400, width: 1000, height: 400))
        #expect(WindowPreset.topLeftQuarter.targetFrame(in: usable, currentSize: current) == WindowFrame(x: 0, y: 0, width: 500, height: 400))
        #expect(WindowPreset.bottomRightQuarter.targetFrame(in: usable, currentSize: current) == WindowFrame(x: 500, y: 400, width: 500, height: 400))
    }

    @Test func maximizeUsesUsableArea() {
        #expect(WindowPreset.maximize.targetFrame(in: usable, currentSize: current) == usable)
    }

    @Test func centerKeepsCurrentSize() {
        let centered = WindowPreset.center.targetFrame(in: usable, currentSize: current)
        #expect(centered == WindowFrame(x: 300, y: 250, width: 400, height: 300))
    }

    @Test func centerClampsToUsableArea() {
        let oversized = WindowFrame(x: 0, y: 0, width: 2000, height: 2000)
        let centered = WindowPreset.center.targetFrame(in: usable, currentSize: oversized)
        #expect(centered == usable)
    }
}

@Suite("Arrange window")
struct ArrangeWindowTests {
    @Test func validationRequiresAnApplication() {
        #expect(ArrangeWindowAction(application: safariReference(), preset: .leftHalf).validate().isValid)

        let wrongKind = ArrangeWindowAction(
            application: ResourceReference(kind: .website, identifier: "https://x.com", label: "x"),
            preset: .leftHalf
        )
        #expect(!wrongKind.validate().isValid)
    }

    @Test func requiredPermissionIsAccessibility() {
        let action = ActionConfiguration.arrangeWindow(ArrangeWindowAction(application: safariReference(), preset: .leftHalf))
        #expect(action.requiredPermissions == [.accessibility])
    }

    @Test func parserRecognizesHalfPresets() {
        let parser = CommandParser()
        let result = parser.parse("put Safari on the left half")

        #expect(result.outcome == .complete)
        #expect(result.clauses[0].kind == .arrangeWindow)
        #expect(result.clauses[0].arrangePreset == .leftHalf)
        #expect(result.clauses[0].arrangeApplicationName == "Safari")
    }

    @Test func parserRecognizesRightHalfAndQuarters() {
        let parser = CommandParser()
        #expect(parser.parse("put Notes on the right half").clauses[0].arrangePreset == .rightHalf)
        #expect(parser.parse("put Safari on the top left").clauses[0].arrangePreset == .topLeftQuarter)
        #expect(parser.parse("maximize Safari").clauses[0].arrangePreset == .maximize)
        #expect(parser.parse("center Notes").clauses[0].arrangePreset == .center)
    }

    @Test func parserNeedsInputWithoutPreset() {
        let result = CommandParser().parse("put Safari")
        #expect(result.outcome == .needsInput)
        #expect(result.hasErrors)
    }

    @Test func composerBuildsArrangeDraftFromText() {
        var document = ComposerDocument()
        document.setText("put Safari on the left half")

        #expect(document.actions.count == 1)
        guard case .arrangeWindow(let name, let resolved, let preset, _) = document.actions[0].draft else {
            Issue.record("Expected an arrange-window draft")
            return
        }
        #expect(name == "Safari")
        #expect(resolved == nil)
        #expect(preset == .leftHalf)
        #expect(document.hasUnresolvedApplications)
        #expect(document.makeDefinition(name: "Test") == nil)
    }

    @Test func resolvingApplicationEnablesDefinition() {
        var document = ComposerDocument()
        document.setText("put Safari on the left half")

        document.resolveApplication(id: document.actions[0].id, reference: safariReference())

        #expect(!document.hasUnresolvedApplications)
        #expect(document.makeDefinition(name: "Test") != nil)
    }

    @Test func canonicalPhraseRoundTrips() {
        let action = ActionConfiguration.arrangeWindow(
            ArrangeWindowAction(application: safariReference(), preset: .leftHalf)
        )
        #expect(CanonicalPhrase.text(for: action) == "Put Safari on the left half")

        let parsed = CommandParser().parse(CanonicalPhrase.command(for: [action]))
        #expect(parsed.outcome == .complete)
        #expect(parsed.clauses[0].arrangePreset == .leftHalf)
        #expect(parsed.clauses[0].arrangeApplicationName == "Safari")
    }

    private func preparer(_ accessibility: PermissionState) -> CreationPreparer {
        CreationPreparer(
            catalog: ArrangeCatalog(installed: ["com.apple.Safari": ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari")]),
            permissions: StubPermissions(accessibility: accessibility)
        )
    }

    private var definition: AutomationDefinition {
        AutomationDefinition(
            name: "Arrange",
            trigger: .manual(ManualTrigger()),
            actions: [.arrangeWindow(ArrangeWindowAction(application: safariReference(), preset: .leftHalf))]
        )
    }

    @Test func previewRequiresAccessibilityPermission() async {
        let denied = await preparer(.denied).prepare(definition)
        #expect(!denied.isValid)
        #expect(denied.actions[0].status == .needsPermission)
        #expect(denied.requiredPermissions == [.accessibility])

        let undetermined = await preparer(.notDetermined).prepare(definition)
        #expect(undetermined.isValid)
        #expect(undetermined.actions[0].status == .needsPermission)

        let granted = await preparer(.granted).prepare(definition)
        #expect(granted.actions[0].status == .ready)
        #expect(granted.isRunnable)
    }
}
