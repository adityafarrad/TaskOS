import Testing
import Foundation
@testable import TaskOSCore

@Suite("Suggestion engine")
struct SuggestionEngineTests {
    private let engine = SuggestionEngine()

    private let applications: [ApplicationResource] = [
        ApplicationResource(bundleIdentifier: "com.apple.Safari", displayName: "Safari"),
        ApplicationResource(bundleIdentifier: "com.apple.Notes", displayName: "Notes"),
        ApplicationResource(bundleIdentifier: "com.apple.Numbers", displayName: "Numbers"),
    ]

    @Test func emptyFieldOffersStarters() {
        let suggestions = engine.suggestions(for: "")
        #expect(suggestions.count <= engine.limit)
        #expect(suggestions.first?.match == .grammarPosition)
        #expect(suggestions.allSatisfy { $0.match == .grammarPosition })
        #expect(suggestions.contains { $0.id == "action.openApplication" })
    }

    @Test func whenContextOffersTriggerSuggestions() {
        let suggestions = engine.suggestions(for: "when")
        #expect(!suggestions.isEmpty)
        #expect(suggestions.allSatisfy { $0.category == .trigger })
        #expect(suggestions.contains { $0.id == "trigger.wake" })
        #expect(suggestions.contains { $0.id == "trigger.battery" })
    }

    @Test func openOffersActionAndApplications() {
        let suggestions = engine.suggestions(for: "open", applications: applications)
        #expect(suggestions.contains { $0.id == "action.openApplication" })
        #expect(suggestions.contains { $0.id == "action.openWebsite" })
        #expect(suggestions.contains { $0.title == "Safari" })
        #expect(suggestions.contains { $0.title == "Notes" })
    }

    @Test func openDomainOffersWebsiteSuggestion() {
        let suggestions = engine.suggestions(for: "open apple.com")
        #expect(suggestions.contains { $0.id.hasPrefix("website.") })
        #expect(suggestions.contains { $0.phrase == "Open https://apple.com" })
    }

    @Test func openPrefixMatchesApplications() {
        let suggestions = engine.suggestions(for: "open Sa", applications: applications)
        #expect(suggestions.first?.title == "Safari")
        #expect(suggestions.first?.match == .prefix)
    }

    @Test func exactApplicationNameRanksFirst() {
        let suggestions = engine.suggestions(for: "open Safari", applications: applications)
        #expect(suggestions.first?.title == "Safari")
        #expect(suggestions.first?.match == .exact)
    }

    @Test func typoDiscoveryFindsNearMatchesButDoesNotAutoSelect() {
        let suggestions = engine.suggestions(for: "open Safri", applications: applications)
        let safari = suggestions.first { $0.title == "Safari" }
        #expect(safari?.match == .typo)
        #expect(suggestions.first?.title == "Safari")
    }

    @Test func typoToleranceIgnoresShortPrefixes() {
        let suggestions = engine.suggestions(for: "open No", applications: applications)
        #expect(suggestions.contains { $0.title == "Notes" && $0.match == .prefix })
        #expect(!suggestions.contains { $0.match == .typo })
    }

    @Test func limitIsEnforced() {
        let many = (0..<20).map { index in
            ApplicationResource(bundleIdentifier: "app.\(index)", displayName: "App \(index)")
        }
        let suggestions = engine.suggestions(for: "open App", applications: many)
        #expect(suggestions.count == 8)
    }

    @Test func alphabeticalTieBreak() {
        let suggestions = engine.suggestions(for: "open N", applications: applications)
        let titles = suggestions.map(\.title)
        #expect(titles.firstIndex(of: "Notes")! < titles.firstIndex(of: "Numbers")!)
    }

    @Test func waitContextOffersDurations() {
        let suggestions = engine.suggestions(for: "wait")
        #expect(!suggestions.isEmpty)
        #expect(suggestions.allSatisfy { $0.phrase.hasPrefix("Wait ") })
    }

    @Test func notificationContextCompletesThePhrase() {
        #expect(engine.suggestions(for: "show").first?.phrase == "Show a notification")
        #expect(engine.suggestions(for: "show a").first?.phrase == "Show a notification")
    }

    @Test func completedNotifyHasNoSuggestions() {
        #expect(engine.suggestions(for: "notify").isEmpty)
    }
}
