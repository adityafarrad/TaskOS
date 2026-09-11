import Testing
import Foundation
import TaskOSCore

@Suite("Capability guide")
struct CapabilityGuideTests {
    private let guides = CapabilityGuideCatalog.standard

    @Test func coversEveryCapability() {
        for id in ActionID.allCases {
            #expect(guides.contains { $0.id == "action.\(id.rawValue)" })
        }
        for id in TriggerID.allCases {
            #expect(guides.contains { $0.id == "trigger.\(id.rawValue)" })
        }
    }

    @Test func guideIdsAreUnique() {
        #expect(Set(guides.map(\.id)).count == guides.count)
    }

    @Test func everyGuideHasAnExample() {
        for guide in guides {
            #expect(!guide.whatItDoes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!guide.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test func actionPermissionsMatchTheWorkflowActions() {
        for guide in guides where guide.kind == .action {
            guard let id = ActionID(rawValue: String(guide.id.dropFirst("action.".count))) else {
                Issue.record("Unknown action guide \(guide.id)")
                continue
            }
            #expect(Set(guide.permissions) == exampleAction(for: id).requiredPermissions)
        }
    }

    @Test func hardwareRequirementsAreStatedForAbsentHardware() {
        #expect(guides.first { $0.id == "trigger.batteryThreshold" }?.hardwareRequirement != nil)
        #expect(guides.first { $0.id == "trigger.displayConnection" }?.hardwareRequirement != nil)
        #expect(guides.first { $0.id == "trigger.externalVolume" }?.hardwareRequirement != nil)
        #expect(guides.first { $0.id == "trigger.schedule" }?.hardwareRequirement == nil)
    }

    @Test func limitationsAreProvidedForRiskyCapabilities() {
        #expect(guides.first { $0.id == "action.quitApplication" }?.limitations != nil)
        #expect(guides.first { $0.id == "action.copyText" }?.limitations != nil)
        #expect(guides.first { $0.id == "action.showNotification" }?.limitations != nil)
    }

    private func exampleAction(for id: ActionID) -> ActionConfiguration {
        let app = ResourceReference.application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        switch id {
        case .openApplication: return .openApplication(OpenApplicationAction(application: app))
        case .hideApplication: return .hideApplication(HideApplicationAction(application: app))
        case .quitApplication: return .quitApplication(QuitApplicationAction(application: app))
        case .openFile: return .openFile(OpenFileAction(target: FileTarget(kind: .file, displayName: "f", path: "/tmp/f")))
        case .revealInFinder: return .revealInFinder(RevealInFinderAction(target: FileTarget(kind: .file, displayName: "f", path: "/tmp/f")))
        case .openWebsite: return .openWebsite(OpenWebsiteAction(url: "https://example.com"))
        case .arrangeWindow: return .arrangeWindow(ArrangeWindowAction(application: app, preset: .leftHalf))
        case .wait: return .wait(WaitAction(duration: 1))
        case .showNotification: return .showNotification(ShowNotificationAction(title: "T", message: "M"))
        case .copyText: return .copyText(CopyTextAction(text: "x"))
        }
    }
}
