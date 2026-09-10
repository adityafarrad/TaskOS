import Testing
import Foundation
import TaskOSCore

@Suite("Automation coding")
struct AutomationCodingTests {
    private func makeDefinition() -> AutomationDefinition {
        AutomationDefinition(
            id: AutomationID(UUID(uuidString: "00000000-0000-0000-0000-0000000000AB")!),
            name: "Canonical slice",
            revision: WorkflowRevision(3),
            trigger: .manual(ManualTrigger()),
            actions: [
                .openApplication(
                    OpenApplicationAction(
                        application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
                    )
                ),
                .wait(WaitAction(duration: 1.5)),
                .showNotification(ShowNotificationAction(title: "Done", message: "Safari is open")),
            ]
        )
    }

    @Test func roundTripPreservesOrderAndParameters() throws {
        let original = makeDefinition()
        let data = try AutomationCoding.encode(original)
        let decoded = try AutomationCoding.decode(data)

        #expect(decoded == original)
        #expect(decoded.actions.map(\.id) == [.openApplication, .wait, .showNotification])
    }

    @Test func rejectsFutureSchemaVersion() throws {
        let data = try AutomationCoding.encode(makeDefinition())
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["schemaVersion"] = 999
        let tampered = try JSONSerialization.data(withJSONObject: object)

        do {
            _ = try AutomationCoding.decode(tampered)
            Issue.record("Expected unsupportedSchemaVersion")
        } catch let error as PersistenceError {
            #expect(error == .unsupportedSchemaVersion(found: 999, supported: 1))
        }
    }

    @Test func rejectsUnknownCapability() throws {
        let data = try AutomationCoding.encode(makeDefinition())
        let json = String(decoding: data, as: UTF8.self)
        let tampered = Data(json.replacingOccurrences(of: "\"wait\"", with: "\"runShell\"").utf8)

        do {
            _ = try AutomationCoding.decode(tampered)
            Issue.record("Expected malformed")
        } catch let error as PersistenceError {
            guard case .malformed = error else {
                Issue.record("Expected malformed, got \(error)")
                return
            }
        }
    }

    @Test func rejectsMalformedPayload() {
        let data = Data("not json".utf8)
        do {
            _ = try AutomationCoding.decode(data)
            Issue.record("Expected malformed")
        } catch let error as PersistenceError {
            guard case .malformed = error else {
                Issue.record("Expected malformed, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }
}
