import Testing
import Foundation
@testable import TaskOSCore

@Suite("Integration and privacy")
struct IntegrationPrivacyTests {
    private struct Catalog: ResourceCatalog {
        var apps: [String: ApplicationResource]

        func application(bundleIdentifier: String) async -> ApplicationResource? {
            apps[bundleIdentifier]
        }

        func installedApplications() async -> [ApplicationResource] {
            Array(apps.values)
        }

        func installedDisplays() async -> [DisplayResource] {
            []
        }

        func fileExists(path: String) async -> Bool? {
            false
        }
    }

    private struct Permissions: PermissionStatusProvider {
        func state(for permission: PermissionKind) async -> PermissionState {
            .granted
        }
    }

    private let journaling = "Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I can journal my day as I keep forgetting?"

    private func resolvedJournalingDefinition() -> AutomationDefinition? {
        var document = ComposerDocument(text: journaling)
        guard let id = document.actions.first?.id else { return nil }
        document.resolveApplication(
            id: id,
            reference: .application(bundleIdentifier: "com.apple.Notes", label: "Notes")
        )
        return document.makeDefinition(name: "Routine")
    }

    private func privacyProbe(_ data: Data) -> String {
        (String(data: data, encoding: .utf8) ?? "").lowercased()
    }

    @Test func savedDefinitionHasNoSourceTextOrRationale() throws {
        guard let definition = resolvedJournalingDefinition() else {
            Issue.record("Expected a definition")
            return
        }

        let encoded = privacyProbe(try AutomationCoding.encode(definition))
        #expect(!encoded.contains("journal"))
        #expect(!encoded.contains("forgetting"))
        #expect(!encoded.contains("hey taskos"))
        #expect(!encoded.contains("every day"))
        #expect(encoded.contains("com.apple.notes"))
        #expect(encoded.contains("\"hour\":21"))
    }

    @Test func portableExportHasNoSourceTextOrRationale() throws {
        guard let definition = resolvedJournalingDefinition() else {
            Issue.record("Expected a definition")
            return
        }

        let exported = privacyProbe(try WorkflowPortability.export(definition))
        #expect(!exported.contains("journal"))
        #expect(!exported.contains("forgetting"))
        #expect(!exported.contains("hey taskos"))
        #expect(!exported.contains("draft"))
        #expect(!exported.contains("isenabled"))
        #expect(!exported.contains("runhistory"))
    }

    @Test func runHistoryHasNoSourceText() throws {
        let record = RunRecord(
            automationID: AutomationID(),
            revision: WorkflowRevision(1),
            automationName: "Routine",
            status: .succeeded,
            startedAt: Date(timeIntervalSince1970: 0),
            finishedAt: Date(timeIntervalSince1970: 1),
            actions: [
                ActionRunRecord(index: 0, actionID: .openApplication, outcome: .succeeded, duration: 0.1),
            ]
        )

        let encoded = privacyProbe(try RunRecordSerialization.encode(record))
        #expect(!encoded.contains("journal"))
        #expect(!encoded.contains("forgetting"))
        #expect(!encoded.contains("hey taskos"))
        #expect(encoded.contains("openapplication"))
    }

    @Test func definitionRoundTripsAndPreparesWithoutAnyParser() async throws {
        let definition = AutomationDefinition(
            name: "No parser",
            revision: WorkflowRevision(1),
            trigger: .manual(ManualTrigger()),
            actions: [
                .openApplication(
                    OpenApplicationAction(
                        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
                    )
                ),
            ]
        )

        let data = try AutomationCoding.encode(definition)
        let decoded = try AutomationCoding.decode(data)
        #expect(decoded == definition)

        let preparer = CreationPreparer(
            catalog: Catalog(
                apps: [
                    "com.apple.Safari": ApplicationResource(
                        bundleIdentifier: "com.apple.Safari",
                        displayName: "Safari"
                    ),
                ]
            ),
            permissions: Permissions()
        )
        let preview = await preparer.prepare(decoded)
        #expect(preview.isRunnable)
        #expect(preview.actions.first?.status == .ready)
        #expect(decoded == definition)
    }

    @Test func legacyDraftDecodesAndVersionTwoRestoresStructuredState() throws {
        let legacy = ComposerDraft(name: "Old", text: "show a notification")
        let legacyData = try JSONEncoder().encode(legacy)
        #expect(!privacyProbe(legacyData).contains("\"payload\""))

        let decodedLegacy = try JSONDecoder().decode(ComposerDraft.self, from: legacyData)
        #expect(decodedLegacy.schemaVersion == 1)
        #expect(decodedLegacy.text == "show a notification")
        #expect(decodedLegacy.authoringSnapshot == nil)

        var document = ComposerDocument(text: "show a notification")
        guard let id = document.actions.first?.id else {
            Issue.record("Expected a notification action")
            return
        }
        document.updateAction(id: id, draft: .showNotification(title: "T", message: "kept"))

        let payload = ComposerDraft.encode(snapshot: document.makeSnapshot())
        let versionTwo = ComposerDraft(name: "New", text: document.text, payload: payload)
        let decoded = try JSONDecoder().decode(ComposerDraft.self, from: try JSONEncoder().encode(versionTwo))
        #expect(decoded.schemaVersion == 2)

        guard let snapshot = decoded.authoringSnapshot,
              let restored = ComposerDocument(snapshot: snapshot) else {
            Issue.record("Expected a structured restore")
            return
        }
        if case .showNotification(_, let message)? = restored.actions.first?.draft {
            #expect(message == "kept")
        } else {
            Issue.record("Expected a restored notification")
        }
    }

    @Test func coreSourcesDoNotPrint() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = packageRoot.appendingPathComponent("Sources/TaskOSCore")
        let files = try FileManager.default.contentsOfDirectory(
            at: sourcesRoot,
            includingPropertiesForKeys: nil
        )

        for file in files where file.pathExtension == "swift" {
            let contents = try String(contentsOf: file, encoding: .utf8)
            #expect(!contents.contains("print("), "\(file.lastPathComponent) must not print")
        }
    }
}
