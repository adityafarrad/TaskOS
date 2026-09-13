import Testing
import Foundation
import TaskOSCore
@testable import TaskOS

@MainActor
@Suite("Completion performance qualification", .serialized)
struct CompletionPerformanceTests {
    @Test func editorToPublishedSuggestionPerformance() {
        let model = ComposerViewModel()
        model.applyApplicationSnapshot(snapshot(count: 5_000))

        for index in 0..<100 {
            model.updateFromEditor(text: "open App\(index)", edit: nil)
            _ = model.visibleSuggestions
        }

        var samples: [Double] = []
        samples.reserveCapacity(1_000)
        for index in 0..<1_000 {
            let command = "open App\(index % 5_000)"
            let start = DispatchTime.now().uptimeNanoseconds
            model.updateFromEditor(text: command, edit: nil)
            _ = model.visibleSuggestions
            let end = DispatchTime.now().uptimeNanoseconds
            samples.append(Double(end - start) / 1_000_000)
        }

        let sorted = samples.sorted()
        func percentile(_ value: Double) -> Double {
            guard !sorted.isEmpty else { return 0 }
            let index = min(sorted.count - 1, max(0, Int((value * Double(sorted.count)).rounded(.up)) - 1))
            return sorted[index]
        }

        print(
            "PERF appCompletion count=1000 apps=5000 p50=\(percentile(0.50)) "
                + "p95=\(percentile(0.95)) p99=\(percentile(0.99)) max=\(sorted.last ?? 0)"
        )
        record(
            "PERF appCompletion count=1000 apps=5000 p50=\(percentile(0.50)) "
                + "p95=\(percentile(0.95)) p99=\(percentile(0.99)) max=\(sorted.last ?? 0)",
            name: "taskos-app-completion-perf.txt"
        )
        #expect(percentile(0.95) <= 100.0)
    }

    @Test func coldApplicationSnapshotPerformance() async {
        let service = ApplicationCatalogService(provider: WorkspaceResourceCatalog())
        let start = DispatchTime.now().uptimeNanoseconds
        let snapshot = await service.refresh()
        let end = DispatchTime.now().uptimeNanoseconds

        print(
            "PERF coldSnapshot apps=\(snapshot.applications.count) "
                + "ms=\(Double(end - start) / 1_000_000)"
        )
        record(
            "PERF coldSnapshot apps=\(snapshot.applications.count) "
                + "ms=\(Double(end - start) / 1_000_000)",
            name: "taskos-app-cold-snapshot-perf.txt"
        )
        #expect(!snapshot.isEmpty)
    }

    private func record(_ line: String, name: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }

    private func snapshot(count: Int) -> ApplicationSnapshot {
        ApplicationSnapshot(
            revision: 1,
            createdAt: Date(),
            applications: (0..<count).map { index in
                ApplicationRecord(
                    bundleIdentifier: "com.example.app\(index)",
                    displayName: "App\(index)",
                    fileName: "App\(index)"
                )
            }
        )
    }
}
