import Testing
import Foundation
@testable import TaskOSCore

@Suite("Canonical phrases")
struct CanonicalPhraseTests {
    private let parser = CommandParser()

    private let safari = ActionConfiguration.openApplication(
        OpenApplicationAction(
            application: .application(bundleIdentifier: "com.apple.Safari", label: "Safari")
        )
    )

    @Test func phrasesForEachCapability() {
        #expect(CanonicalPhrase.text(for: .manual(ManualTrigger())) == "Manually")
        #expect(CanonicalPhrase.text(for: safari) == "Open Safari")
        #expect(CanonicalPhrase.text(for: .wait(WaitAction(duration: 1.5))) == "Wait 1.5 seconds")
        #expect(CanonicalPhrase.text(for: .wait(WaitAction(duration: 2))) == "Wait 2 seconds")
        #expect(
            CanonicalPhrase.text(for: .showNotification(ShowNotificationAction(title: "a", message: "b")))
                == "Show a notification"
        )
    }

    @Test func commandRoundTripsThroughParser() {
        let actions: [ActionConfiguration] = [
            safari,
            .wait(WaitAction(duration: 1.5)),
            .showNotification(ShowNotificationAction(title: "Done", message: "x")),
        ]

        let command = CanonicalPhrase.command(for: actions)
        #expect(command == "Open Safari, then Wait 1.5 seconds, then Show a notification")

        let parsed = parser.parse(command)
        #expect(parsed.outcome == .complete)
        #expect(parsed.clauses.map(\.kind) == [.openApplication, .wait, .showNotification])
        #expect(parsed.clauses[0].resourceNames == ["Safari"])
        #expect(parsed.clauses[1].duration == 1.5)
    }
}
