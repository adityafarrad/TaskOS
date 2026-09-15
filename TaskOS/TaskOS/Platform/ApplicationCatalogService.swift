import Foundation
import TaskOSCore

nonisolated protocol ApplicationRecordProviding: Sendable {
    func installedApplicationRecords() async -> [ApplicationRecord]
}

extension WorkspaceResourceCatalog: ApplicationRecordProviding {}

actor ApplicationCatalogService {
    private let provider: any ApplicationRecordProviding
    private var current = ApplicationSnapshot.empty
    private var refreshTask: Task<ApplicationSnapshot, Never>?
    private var revisionCounter = 0
    private var generation = 0

    init(provider: any ApplicationRecordProviding) {
        self.provider = provider
    }

    func snapshot() -> ApplicationSnapshot {
        current
    }

    func refresh() async -> ApplicationSnapshot {
        if let refreshTask {
            return await refreshTask.value
        }

        revisionCounter += 1
        let revision = revisionCounter
        let startGeneration = generation
        let provider = self.provider
        let task = Task<ApplicationSnapshot, Never> {
            let records = await provider.installedApplicationRecords()
            return ApplicationSnapshot(
                revision: revision,
                createdAt: Date(),
                applications: records
            )
        }
        refreshTask = task

        let snapshot = await task.value
        refreshTask = nil
        if startGeneration == generation, snapshot.revision >= current.revision {
            current = snapshot
        }
        return current
    }

    func reset() {
        generation += 1
        current = .empty
        refreshTask?.cancel()
        refreshTask = nil
    }
}
