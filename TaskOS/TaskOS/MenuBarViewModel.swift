import AppKit
import Foundation
import Observation
import TaskOSCore

@MainActor
@Observable
final class MenuBarViewModel {
    private(set) var workflows: [SavedWorkflow] = []
    private(set) var status = "Idle"
    private(set) var isRunning = false
    var automaticTriggersPaused = false

    private let composition: AppComposition
    private var runTask: Task<Void, Never>?

    init(composition: AppComposition = .shared) {
        self.composition = composition
        load()
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            let loaded = (try? await self.composition.repository.loadAll()) ?? []
            self.workflows = loaded
        }
    }

    func run(_ workflow: SavedWorkflow) {
        guard !isRunning else { return }
        isRunning = true
        status = "Running \(workflow.name)..."

        runTask = Task { [weak self] in
            guard let self else { return }
            let record = await self.composition.runner.run(workflow.definition)
            try? await self.composition.runHistory.append(record)
            self.status = "\(workflow.name): \(record.status.rawValue)"
            self.isRunning = false
            self.runTask = nil
        }
    }

    func cancel() {
        guard isRunning else { return }
        runTask?.cancel()
        status = "Cancelling..."
    }

    func toggleAutomaticTriggers() {
        automaticTriggersPaused.toggle()
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
