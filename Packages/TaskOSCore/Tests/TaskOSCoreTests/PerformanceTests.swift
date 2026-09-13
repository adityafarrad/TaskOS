import Testing
import Foundation
@testable import TaskOSCore

@Suite("Performance qualification", .serialized)
struct PerformanceTests {
    private static let perfEnabled = ProcessInfo.processInfo.environment["TASKOS_PERF"] == "1"

    private static let corpus: [String] = [
        "open Safari",
        "open Notes and Safari",
        "Open \"Research and Notes\", then open Safari",
        "launch Google Chrome",
        "hide Mail",
        "quit Safari and Notes",
        "wait 1 second",
        "wait 30 seconds",
        "show a notification",
        "notify",
        "copy \"meeting agenda\"",
        "copy \"a, then b; c\"",
        "reveal the selected item",
        "open the selected file",
        "open the selected folder",
        "put Safari on the left half",
        "put Notes on the top-left quarter",
        "maximize Safari",
        "center Notes",
        "open https://example.com/path?q=1#frag",
        "every day at 9 am, then open Safari",
        "every weekday at 8:15 am, then open Notes",
        "every monday and friday at 9 am, then open Safari",
        "every 30 minutes, then open Safari",
        "in 45 minutes, then show a notification",
        "once on 2026-09-20 at 09:00, then open Notes",
        "when Safari opens, then show a notification",
        "when the Mac wakes, then open Safari",
        "when a display connects, then open Notes",
        "when an external drive mounts, then open the selected folder",
        "when the Mac switches to battery, then open Safari",
        "when the battery drops below 20%, then show a notification",
        "Hey TaskOS, can you make sure at 9:00 PM every day you open Notes, so that I can journal my day as I keep forgetting?",
    ]

    private struct Percentiles {
        let p50: Double
        let p95: Double
        let p99: Double
        let maximum: Double
    }

    private static func percentiles(_ samples: [Double]) -> Percentiles {
        let sorted = samples.sorted()
        func value(_ percentile: Double) -> Double {
            guard !sorted.isEmpty else { return 0 }
            let index = min(sorted.count - 1, max(0, Int((percentile * Double(sorted.count)).rounded(.up)) - 1))
            return sorted[index]
        }
        return Percentiles(p50: value(0.50), p95: value(0.95), p99: value(0.99), maximum: sorted.last ?? 0)
    }

    private static func measure(_ body: () -> Void) -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        body()
        let end = DispatchTime.now().uptimeNanoseconds
        return Double(end - start) / 1_000_000
    }

    private static func syntheticApplications(_ count: Int) -> [ApplicationResource] {
        (0..<count).map { index in
            ApplicationResource(
                bundleIdentifier: "com.example.app\(index)",
                displayName: "App\(index)"
            )
        }
    }

    @Test(.enabled(if: perfEnabled))
    func parserPerformance() {
        let parser = CommandParser()
        for index in 0..<100 {
            _ = parser.parse(Self.corpus[index % Self.corpus.count])
        }

        var samples: [Double] = []
        samples.reserveCapacity(10_000)
        for index in 0..<10_000 {
            let command = Self.corpus[index % Self.corpus.count]
            samples.append(Self.measure { _ = parser.parse(command) })
        }

        let report = Self.percentiles(samples)
        print("PERF parser count=10000 p50=\(report.p50) p95=\(report.p95) p99=\(report.p99) max=\(report.maximum)")
        #expect(report.p95 <= 10.0)
        #expect(report.p99 <= 25.0)
    }

    @Test(.enabled(if: perfEnabled))
    func applicationSearchPerformance() {
        let engine = SuggestionEngine()
        let applications = Self.syntheticApplications(5_000)

        for index in 0..<100 {
            _ = engine.suggestions(for: "open App\(index)", applications: applications)
        }

        var samples: [Double] = []
        samples.reserveCapacity(1_000)
        for index in 0..<1_000 {
            let query = "open App\(index % 5_000)"
            samples.append(Self.measure { _ = engine.suggestions(for: query, applications: applications) })
        }

        let report = Self.percentiles(samples)
        print("PERF search count=1000 apps=5000 p50=\(report.p50) p95=\(report.p95) p99=\(report.p99) max=\(report.maximum)")
        #expect(report.p95 <= 100.0)
    }

    @Test(.enabled(if: perfEnabled))
    func endToEndCompletionPerformance() {
        let engine = SuggestionEngine()
        let applications = Self.syntheticApplications(5_000)

        for index in 0..<100 {
            let document = ComposerDocument(text: "open App\(index)")
            _ = engine.suggestions(for: document.text, applications: applications)
        }

        var samples: [Double] = []
        samples.reserveCapacity(1_000)
        for index in 0..<1_000 {
            let command = "open App\(index % 5_000)"
            samples.append(
                Self.measure {
                    let document = ComposerDocument(text: command)
                    _ = engine.suggestions(for: document.text, applications: applications)
                }
            )
        }

        let report = Self.percentiles(samples)
        print("PERF completion count=1000 apps=5000 p50=\(report.p50) p95=\(report.p95) p99=\(report.p99) max=\(report.maximum)")
        #expect(report.p95 <= 100.0)
    }

    @Test(.enabled(if: perfEnabled))
    func snapshotBuildPerformance() {
        var samples: [Double] = []
        for _ in 0..<50 {
            samples.append(
                Self.measure {
                    let records = (0..<5_000).map { index in
                        ApplicationRecord(
                            bundleIdentifier: "com.example.app\(index)",
                            displayName: "App\(index)",
                            fileName: "App\(index)"
                        )
                    }
                    _ = ApplicationSnapshot(revision: 1, createdAt: Date(), applications: records)
                }
            )
        }
        let report = Self.percentiles(samples)
        print("PERF snapshot count=50 apps=5000 p50=\(report.p50) p95=\(report.p95) max=\(report.maximum)")
    }
}
