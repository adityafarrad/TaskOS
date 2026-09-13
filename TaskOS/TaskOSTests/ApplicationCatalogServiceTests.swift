import Testing
import Foundation
import TaskOSCore
@testable import TaskOS

private actor FakeApplicationProvider: ApplicationRecordProviding {
    private var records: [ApplicationRecord]
    private let delayMilliseconds: Int
    private var calls = 0

    init(records: [ApplicationRecord], delayMilliseconds: Int = 0) {
        self.records = records
        self.delayMilliseconds = delayMilliseconds
    }

    func installedApplicationRecords() async -> [ApplicationRecord] {
        calls += 1
        if delayMilliseconds > 0 {
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))
        }
        return records
    }

    func setRecords(_ records: [ApplicationRecord]) {
        self.records = records
    }

    func callCount() -> Int {
        calls
    }
}

@Suite("Application catalog service", .serialized)
struct ApplicationCatalogServiceTests {
    private func record(_ name: String) -> ApplicationRecord {
        ApplicationRecord(
            bundleIdentifier: "com.example.\(name)",
            displayName: name,
            fileName: name
        )
    }

    @Test func concurrentRefreshesCoalesce() async {
        let provider = FakeApplicationProvider(records: [record("Safari")], delayMilliseconds: 80)
        let service = ApplicationCatalogService(provider: provider)

        async let first = service.refresh()
        async let second = service.refresh()
        let snapshots = await [first, second]

        #expect(snapshots[0] == snapshots[1])
        #expect(snapshots[0].revision == 1)
        #expect(await provider.callCount() == 1)
    }

    @Test func refreshesAdvanceRevisionAndKeepTheLatest() async {
        let provider = FakeApplicationProvider(records: [record("Safari")])
        let service = ApplicationCatalogService(provider: provider)

        let first = await service.refresh()
        #expect(first.revision == 1)

        await provider.setRecords([record("Notes")])
        let second = await service.refresh()
        #expect(second.revision == 2)
        #expect(second.applications.map(\.displayName) == ["Notes"])

        let current = await service.snapshot()
        #expect(current == second)
    }

    @Test func resetClearsTheSnapshot() async {
        let provider = FakeApplicationProvider(records: [record("Safari")])
        let service = ApplicationCatalogService(provider: provider)

        _ = await service.refresh()
        await service.reset()
        #expect(await service.snapshot() == .empty)
    }
}
