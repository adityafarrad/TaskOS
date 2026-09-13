import Testing
import Foundation
@testable import TaskOSCore

@Suite("Performance qualification", .serialized)
struct PerformanceTests {
    private static let perfEnabled = ProcessInfo.processInfo.environment["TASKOS_PERF"] == "1"

    private static let corpus: [String] = {
        LanguageCorpus.positiveCommands(count: 2_000).map(\.text) + LanguageCorpus.negativeCommands()
    }()

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
        print("PERF parser count=10000 corpus=\(Self.corpus.count) p50=\(report.p50) p95=\(report.p95) p99=\(report.p99) max=\(report.maximum)")
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
    func parseAndSuggestionEnginePerformance() {
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
        print("PERF parsePlusEngine count=1000 apps=5000 p50=\(report.p50) p95=\(report.p95) p99=\(report.p99) max=\(report.maximum)")
    }
}
