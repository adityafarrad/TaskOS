import Testing
import Foundation
@testable import TaskOSCore

@Suite("Result validity and typo bounds")
struct ResultValidityTests {
    private let engine = SuggestionEngine()

    private func apps(_ names: [String]) -> [ApplicationResource] {
        names.map { ApplicationResource(bundleIdentifier: "com.example.\($0)", displayName: $0) }
    }

    private func hasTypo(_ query: String, apps names: [String]) -> Bool {
        engine.suggestions(for: query, applications: apps(names))
            .contains { $0.match == .typo }
    }

    @Test func shortQueriesProduceNoTypoProposals() {
        #expect(!hasTypo("open Safr", apps: ["Safari"]))
        #expect(!hasTypo("open No", apps: ["Notes"]))
    }

    @Test func fiveToEightCharactersAllowOnlyDistanceOne() {
        #expect(hasTypo("open Safri", apps: ["Safari"]))
        #expect(!hasTypo("open Ntxes", apps: ["Notes"]))
    }

    @Test func nineToSixtyFourCharactersAllowDistanceTwoWithinNormalizedBound() {
        #expect(hasTypo("open Aplications", apps: ["Applications"]))
        #expect(!hasTypo("open Completely", apps: ["Notes"]))
    }

    @Test func veryLongQueriesProduceNoTypoProposals() {
        let long = String(repeating: "a", count: 65)
        #expect(!hasTypo("open \(long)", apps: ["Applications"]))
    }

    @Test func atMostThreeTypoProposals() {
        let suffixes = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        let names = suffixes.map { "test\($0)" }
        let suggestions = engine.suggestions(for: "open tests", applications: apps(names))
        #expect(suggestions.filter { $0.match == .typo }.count <= 3)
    }

    @Test func typoSearchIsBoundedToApplicationCap() {
        var names = (0..<CommandLimits.maximumApplications).map { "App\($0)" }
        names.append("App\(CommandLimits.maximumApplications)")

        let withinCap = engine.suggestions(for: "open App4999", applications: apps(names))
        #expect(withinCap.contains { $0.title == "App4999" })

        let beyondCap = engine.suggestions(for: "open App5000", applications: apps(names))
        #expect(!beyondCap.contains { $0.title == "App5000" })
    }

    @Test func completionKeysDistinguishGenerationAndCursor() {
        let session = UUID()
        let base = CompletionKey(
            sessionID: session,
            sourceGeneration: 1,
            cursor: SourceSpan(start: 0, end: 0),
            hasMarkedText: false,
            languageRevision: 1,
            snapshotRevision: 1
        )
        let nextGeneration = CompletionKey(
            sessionID: session,
            sourceGeneration: 2,
            cursor: SourceSpan(start: 0, end: 0),
            hasMarkedText: false,
            languageRevision: 1,
            snapshotRevision: 1
        )
        let movedCursor = CompletionKey(
            sessionID: session,
            sourceGeneration: 1,
            cursor: SourceSpan(start: 5, end: 5),
            hasMarkedText: false,
            languageRevision: 1,
            snapshotRevision: 1
        )
        let newSnapshot = CompletionKey(
            sessionID: session,
            sourceGeneration: 1,
            cursor: SourceSpan(start: 0, end: 0),
            hasMarkedText: false,
            languageRevision: 1,
            snapshotRevision: 2
        )

        #expect(base != nextGeneration)
        #expect(base != movedCursor)
        #expect(base != newSnapshot)
    }

    @Test func preparationAndResourceKeysAreTypedByIdentity() {
        let session = UUID()
        let node = UUID()

        let preparation = PreparationKey(sessionID: session, authoringRevision: WorkflowRevision(3))
        #expect(preparation.authoringRevision == WorkflowRevision(3))
        #expect(preparation != PreparationKey(sessionID: session, authoringRevision: WorkflowRevision(4)))

        let selection = ResourceSelectionKey(
            sessionID: session,
            nodeID: node,
            slot: "application",
            nodeRevision: WorkflowRevision(2),
            snapshotRevision: 5
        )
        #expect(selection != ResourceSelectionKey(
            sessionID: session,
            nodeID: node,
            slot: "application",
            nodeRevision: WorkflowRevision(3),
            snapshotRevision: 5
        ))
    }
}
