import Foundation
@testable import TaskOSCore

actor FileAutomationRepository: AutomationRepository {
    private let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL) {
        self.directory = directory
    }

    func loadAll() async throws -> [SavedWorkflow] {
        try ensureDirectory()
        let entries = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []

        var workflows: [SavedWorkflow] = []
        for entry in entries where entry.pathExtension == "json" {
            let data = try Data(contentsOf: entry)
            workflows.append(try SavedWorkflowSerialization.decode(data))
        }

        return workflows.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ workflow: SavedWorkflow) async throws {
        try ensureDirectory()
        let data = try SavedWorkflowSerialization.encode(workflow)
        try data.write(to: fileURL(for: workflow.id), options: [.atomic])
    }

    func delete(id: AutomationID) async throws {
        let url = fileURL(for: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func ensureDirectory() throws {
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for id: AutomationID) -> URL {
        directory.appendingPathComponent("\(id.rawValue.uuidString).json")
    }
}

actor InMemoryAutomationRepository: AutomationRepository {
    private var storage: [AutomationID: SavedWorkflow] = [:]

    init() {}

    func loadAll() async throws -> [SavedWorkflow] {
        storage.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ workflow: SavedWorkflow) async throws {
        storage[workflow.id] = workflow
    }

    func delete(id: AutomationID) async throws {
        storage[id] = nil
    }
}

actor InMemoryRunHistoryRepository: RunHistoryRepository {
    private var storage: [RunRecord] = []

    init() {}

    func recentRuns(limit: Int) async throws -> [RunRecord] {
        Array(storage.sorted { $0.startedAt > $1.startedAt }.prefix(limit))
    }

    func append(_ record: RunRecord) async throws {
        storage.append(record)
    }

    func clear() async throws {
        storage.removeAll()
    }
}
