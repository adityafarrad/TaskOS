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
    private(set) var queuedCount = 0
    private(set) var automaticTriggersPaused = false

    private let composition: AppComposition

    init(composition: AppComposition = .shared) {
        self.composition = composition
        load()
        refreshStatus()
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            let loaded = (try? await self.composition.repository.loadAll()) ?? []
            self.workflows = loaded
        }
    }

    func run(_ workflow: SavedWorkflow) {
        Task { [weak self] in
            guard let self else { return }
            let outcome = await self.composition.coordinator.submit(workflow.definition, source: .manual)
            switch outcome {
            case .started:
                self.status = "Running \(workflow.name)..."
            case .queued:
                self.status = "Queued \(workflow.name)"
            case .queueFull:
                self.status = "Queue is full"
            case .rejected(let message):
                self.status = "Cannot run: \(message)"
            case .suppressedDuplicate, .suppressedCooldown,
                 .suppressedPaused, .suppressedSessionNotReady:
                self.status = "Not started"
            }

            await self.composition.coordinator.waitUntilIdle()
            await self.updateStatus()
        }
    }

    func cancel() {
        Task { [weak self] in
            guard let self else { return }
            await self.composition.coordinator.cancelAll()
            await self.updateStatus()
        }
    }

    func toggleAutomaticTriggers() {
        Task { [weak self] in
            guard let self else { return }
            if self.automaticTriggersPaused {
                await self.composition.coordinator.resumeAutomaticTriggers()
            } else {
                await self.composition.coordinator.pauseAutomaticTriggers()
            }
            await self.updateStatus()
        }
    }

    func refreshStatus() {
        Task { [weak self] in
            await self?.updateStatus()
        }
    }

    private func updateStatus() async {
        let snapshot = await composition.coordinator.status()
        isRunning = snapshot.isRunning
        queuedCount = snapshot.queuedCount
        automaticTriggersPaused = snapshot.isPaused

        if let name = snapshot.currentName {
            status = "Running \(name)..."
        } else if snapshot.queuedCount > 0 {
            status = "Queued \(snapshot.queuedCount)"
        } else {
            status = "Idle"
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
