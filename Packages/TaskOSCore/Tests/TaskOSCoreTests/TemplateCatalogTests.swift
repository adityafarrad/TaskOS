import Testing
import Foundation
import TaskOSCore

@Suite("Template catalog")
struct TemplateCatalogTests {
    private let catalog = TemplateCatalog.standard
    private let registry = CapabilityRegistry.standard

    @Test func shipsTwelveTemplatesWithUniqueIds() {
        #expect(catalog.templates.count == 12)
        #expect(Set(catalog.templates.map(\.id)).count == 12)
    }

    @Test func templatesUseOnlyRegisteredCapabilities() {
        for template in catalog.templates {
            #expect(registry.descriptor(for: template.trigger.triggerID) != nil, "\(template.id) trigger")
            for action in template.actions {
                #expect(registry.descriptor(for: action.actionID) != nil, "\(template.id) action \(action.actionID)")
            }
        }
    }

    @Test func templatesHaveNamesAndSummaries() {
        for template in catalog.templates {
            #expect(!template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!template.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test func resolvableTemplatesProduceDefinitions() {
        let breakTemplate = catalog.template(id: "break")
        #expect(breakTemplate?.document().makeDefinition(name: "Break") != nil)

        let agenda = catalog.template(id: "agenda")
        #expect(agenda?.document().makeDefinition(name: "Agenda") != nil)

        let battery = catalog.template(id: "battery")
        #expect(battery?.document().makeDefinition(name: "Battery") != nil)
    }

    @Test func templatesWithPlaceholdersStayUnresolved() {
        let workday = catalog.template(id: "workday")
        guard let document = workday?.document() else {
            Issue.record("Expected a workday template")
            return
        }
        #expect(document.hasUnresolvedActions)
        #expect(document.makeDefinition(name: "Workday") == nil)
        #expect(document.text.contains("When") || document.text.contains("Open"))
    }

    @Test func templateDocumentRendersTriggerPhrase() {
        let battery = catalog.template(id: "battery")?.document()
        #expect(battery?.trigger == .batteryThreshold(comparator: .below, percentage: 20))
        #expect(battery?.text.contains("When the battery drops below 20%") == true)
    }

    @Test func limitationsAreStatedWhereRelevant() {
        #expect(catalog.template(id: "writing")?.limitations != nil)
        #expect(catalog.template(id: "meeting")?.limitations != nil)
    }
}
