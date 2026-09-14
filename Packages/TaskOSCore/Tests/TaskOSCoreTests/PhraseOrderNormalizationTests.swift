import Testing
import Foundation
@testable import TaskOSCore

@Suite("Phrase order normalization")
struct PhraseOrderNormalizationTests {
    private let parser = CommandParser()

    private struct Plan: Equatable {
        let trigger: ComposerTriggerDraft
        let actions: [String]
    }

    private func plan(for text: String) -> Plan? {
        let document = ComposerDocument(text: text)
        guard document.parseOutcome == .complete, !document.hasUnresolvedText else { return nil }
        let actions = document.actions.compactMap { action -> String? in
            if case .openApplication(let name, _) = action.draft { return name.lowercased() }
            return nil
        }
        return Plan(trigger: document.trigger, actions: actions)
    }

    @Test func equivalentDailyPhrasingsProduceTheSamePlan() {
        let canonical = "Every day at 9:00 PM, then open Notes"
        guard let expected = plan(for: canonical) else {
            Issue.record("The canonical phrase did not produce a plan")
            return
        }

        let variants = [
            "every day at 9 pm open notes",
            "every day at 9pm open notes",
            "every day at 21:00 open notes",
            "everyday at 9 pm open notes",
            "EVERYDAY AT 9PM OPEN NOTES",
            "at 9 pm every day open notes",
            "at 9 pm everyday open notes",
            "at 9:00 pm every day you open notes",
            "at 21:00 everyday you open notes",
            "at 9 pm open notes every day",
            "at 9pm open notes everyday",
            "open notes every day at 9 pm",
            "open notes everyday at 9pm",
            "open notes at 9 pm every day",
            "open notes at 21:00 everyday",
            "at 9 pm every day, then open notes",
            "please open notes every day at 9 pm",
            "can you open notes everyday at 9 pm",
            "could you every day at 9pm open notes",
            "Please, at 9 PM every day, open Notes.",
        ]

        for (index, variant) in variants.enumerated() {
            guard let variantPlan = plan(for: variant) else {
                Issue.record("variant \(index) did not produce a complete plan")
                continue
            }
            #expect(variantPlan == expected, "variant \(index)")
        }
    }

    @Test func dailyTimeFormatsAreEquivalent() {
        let expectedClock = ParsedSchedule.daily(hour: 21, minute: 0)
        for (index, text) in [
            "every day at 9 pm open notes",
            "every day at 9pm open notes",
            "every day at 9:00 pm open notes",
            "every day at 21:00 open notes",
        ].enumerated() {
            let parsed = parser.parse(text)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.clauses.first { $0.kind == .schedule }?.schedule == expectedClock, "case \(index)")
            #expect(plan(for: text)?.trigger == .daily(hour: 21, minute: 0), "case \(index)")
        }
    }

    @Test func triggerAndActionOrderingBothWays() {
        for (index, text) in [
            "every day at 9 am open notes",
            "at 9 am every day open notes",
            "open notes every day at 9 am",
            "open notes at 9 am every day",
            "every day at 9 am, then open notes",
            "open notes, then every day at 9 am",
        ].enumerated() {
            let parsed = parser.parse(text)
            #expect(parsed.outcome == .complete, "case \(index)")
            #expect(parsed.coverage.isComplete, "case \(index)")
        }
    }

    @Test func ambiguousOrIncompletePhrasingsRemainBlocked() {
        let blocked = [
            "at 9 am open notes",
            "every day open notes",
            "everyday open notes",
            "open notes every day",
            "open notes at 9 am",
            "at 9 am every week open notes",
            "at 9 am open notes at 10 am every day",
            "at 9 am open notes every day every day",
            "at 09:00 open notes every day",
            "every day at 09:00 open notes",
            "open notes every day at 9 am then open safari",
            "every day at 9 am open notes every day",
            "at 9 am hello every day",
            "at 9 am open notes every 30 minutes",
        ]

        for (index, text) in blocked.enumerated() {
            let parsed = parser.parse(text)
            #expect(parsed.outcome != .complete, "case \(index)")
            #expect(ComposerDocument(text: text).makeDefinition(name: "Blocked") == nil, "case \(index)")
        }
    }
}
