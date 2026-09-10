import Testing
import Foundation
import TaskOSCore

@Suite("Capability registry")
struct CapabilityRegistryTests {
    @Test func standardRegistryIsConsistent() {
        #expect(CapabilityRegistry.standard.consistencyIssues().isEmpty)
    }

    @Test func everyKnownCapabilityHasADescriptor() {
        let registry = CapabilityRegistry.standard
        for id in TriggerID.allCases {
            #expect(registry.descriptor(for: id) != nil)
        }
        for id in ActionID.allCases {
            #expect(registry.descriptor(for: id) != nil)
        }
    }

    @Test func missingDescriptorIsReported() {
        let registry = CapabilityRegistry(
            triggers: [
                .manual: CapabilityDescriptor(title: "Manual", summary: "")
            ],
            actions: [
                .openApplication: CapabilityDescriptor(title: "Open Application", summary: "")
            ]
        )
        let issues = registry.consistencyIssues()
        #expect(issues.contains { $0.contains("wait") })
        #expect(issues.contains { $0.contains("showNotification") })
    }
}
