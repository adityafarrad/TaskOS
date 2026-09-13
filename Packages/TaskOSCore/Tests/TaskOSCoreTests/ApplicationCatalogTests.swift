import Testing
import Foundation
@testable import TaskOSCore

@Suite("Application catalog")
struct ApplicationCatalogTests {
    private func record(
        _ displayName: String,
        fileName: String? = nil,
        bundle: String? = nil,
        aliases: [String] = []
    ) -> ApplicationRecord {
        ApplicationRecord(
            bundleIdentifier: bundle ?? "com.example.\(displayName.replacingOccurrences(of: " ", with: ""))",
            displayName: displayName,
            fileName: fileName ?? displayName,
            url: URL(fileURLWithPath: "/Applications/\(displayName).app"),
            aliases: aliases
        )
    }

    private func snapshot(_ records: [ApplicationRecord], revision: Int = 1) -> ApplicationSnapshot {
        ApplicationSnapshot(revision: revision, createdAt: Date(timeIntervalSince1970: 0), applications: records)
    }

    @Test func normalizeStripsAppSuffixAndCase() {
        #expect(ApplicationResolver.normalize("  Safari  ") == "safari")
        #expect(ApplicationResolver.normalize("Safari.app") == "safari")
        #expect(ApplicationResolver.normalize("VS Code") == "vs code")
    }

    @Test func emptyCatalogAndSingleResolution() {
        #expect(ApplicationResolver.resolve("Safari", in: .empty) == .emptyCatalog)

        let apps = snapshot([record("Safari")])
        #expect(ApplicationResolver.resolve("Safari", in: apps) == .resolved(record("Safari")))
        #expect(ApplicationResolver.resolve("safari", in: apps) == .resolved(record("Safari")))
        #expect(ApplicationResolver.resolve("Missing", in: apps) == .missing)
    }

    @Test func displayNameFileNameAndAliasAllResolve() {
        let apps = snapshot([
            record("Visual Studio Code", fileName: "VSCode", aliases: ["VS Code"]),
        ])
        #expect(ApplicationResolver.resolve("Visual Studio Code", in: apps) == .resolved(record("Visual Studio Code", fileName: "VSCode", aliases: ["VS Code"])))
        #expect(ApplicationResolver.resolve("VSCode", in: apps) == .resolved(record("Visual Studio Code", fileName: "VSCode", aliases: ["VS Code"])))
        #expect(ApplicationResolver.resolve("vs code.app", in: apps) == .resolved(record("Visual Studio Code", fileName: "VSCode", aliases: ["VS Code"])))
    }

    @Test func duplicateDisplayNameIsAmbiguousNotFirst() {
        let apps = snapshot([
            record("Notes", bundle: "com.example.NotesA"),
            record("Notes", bundle: "com.example.NotesB"),
        ])

        guard case .ambiguous(let matches) = ApplicationResolver.resolve("Notes", in: apps) else {
            Issue.record("Expected ambiguity")
            return
        }
        #expect(matches.count == 2)
    }

    @Test func overCapCatalogRefusesAutomaticResolution() {
        let many = (0..<CommandLimits.maximumApplications).map { record("App \($0)") }
        #expect(!snapshot(many).isOverCap)
        guard case .resolved = ApplicationResolver.resolve("App 0", in: snapshot(many)) else {
            Issue.record("Expected a resolution at the cap")
            return
        }

        let tooMany = (0...CommandLimits.maximumApplications).map { record("App \($0)") }
        #expect(snapshot(tooMany).isOverCap)
        #expect(ApplicationResolver.resolve("App 0", in: snapshot(tooMany)) == .overCap)
        #expect(ApplicationListGrouper.group(segments: ["App 0"], snapshot: snapshot(tooMany)) == .overCap)
    }

    @Test func singleGroupingWhenNamesAreUnambiguous() {
        let apps = snapshot([record("Research"), record("Notes"), record("Safari")])
        guard case .single(let grouping) = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected a single grouping")
            return
        }
        #expect(grouping.records.map(\.displayName) == ["Research", "Notes", "Safari"])
        #expect(grouping.rewrites == ["Open Research, then open Notes, then open Safari"])
    }

    @Test func quotedConnectorBearingNameIsOneSegment() {
        let apps = snapshot([
            record("Research"),
            record("Notes"),
            record("Research and Notes"),
            record("Safari"),
        ])

        guard case .single(let grouping) = ApplicationListGrouper.group(
            segments: ["Research and Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected a single grouping")
            return
        }
        #expect(grouping.records.map(\.displayName) == ["Research and Notes", "Safari"])
    }

    @Test func wholeListCollisionIsAmbiguousWithRewrites() {
        let apps = snapshot([
            record("Research"),
            record("Notes"),
            record("Research and Notes"),
            record("Safari"),
        ])

        guard case .ambiguous(let groupings) = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected ambiguity")
            return
        }

        let rewrites = Set(groupings.flatMap(\.rewrites))
        #expect(rewrites.contains("Open \"Research and Notes\", then open Safari"))
        #expect(rewrites.contains("Open Research, then open Notes, then open Safari"))
    }

    @Test func wholeListMergedCollisionIsAmbiguous() {
        let apps = snapshot([
            record("Research"),
            record("Notes"),
            record("Safari"),
            record("Research and Notes and Safari"),
        ])

        guard case .ambiguous = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected ambiguity")
            return
        }
    }

    @Test func partialSpanCollisionIsAmbiguous() {
        let apps = snapshot([
            record("Research"),
            record("Notes"),
            record("Safari"),
            record("Notes and Safari"),
        ])

        guard case .ambiguous = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected ambiguity")
            return
        }
    }

    @Test func moreThanTwoGroupingsAreStillAmbiguous() {
        let apps = snapshot([
            record("Research"),
            record("Notes"),
            record("Safari"),
            record("Research and Notes"),
            record("Notes and Safari"),
        ])

        guard case .ambiguous(let groupings) = ApplicationListGrouper.group(
            segments: ["Research", "Notes", "Safari"],
            snapshot: apps
        ) else {
            Issue.record("Expected ambiguity")
            return
        }
        #expect(groupings.count >= 2)
    }

    @Test func unresolvedNamesAreReported() {
        let apps = snapshot([record("Safari")])
        #expect(
            ApplicationListGrouper.group(segments: ["Frobnicator"], snapshot: apps)
                == .unresolved(["Frobnicator"])
        )
    }

    @Test func noApplicationIsSelectedByListOrder() {
        let apps = snapshot([
            record("Notes", bundle: "com.example.NotesA"),
            record("Notes", bundle: "com.example.NotesB"),
        ])

        guard case .ambiguous(let matches) = ApplicationResolver.resolve("Notes", in: apps) else {
            Issue.record("Expected ambiguity")
            return
        }
        #expect(Set(matches.map(\.bundleIdentifier)) == ["com.example.NotesA", "com.example.NotesB"])
    }
}
