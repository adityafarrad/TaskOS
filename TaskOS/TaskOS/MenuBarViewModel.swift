import AppKit
import Foundation
import Observation
import TaskOSCore

@MainActor
@Observable
final class MenuBarViewModel {
    static let shared = MenuBarViewModel()

    private(set) var workflows: [SavedWorkflow] = []
    private(set) var status = "Idle"
    private(set) var isRunning = false
    private(set) var queuedCount = 0
    private(set) var automaticTriggersPaused = false
    private(set) var libraryError: String?

    private let composition: AppComposition
    private var libraryToken: NSObjectProtocol?

    private init(composition: AppComposition = .shared) {
        self.composition = composition
        load()
        refreshStatus()
        recoverInterruptedRuns()
        libraryToken = NotificationCenter.default.addObserver(
            forName: .taskOSWorkflowLibraryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.load() }
        }
    }

    private func recoverInterruptedRuns() {
        Task { [composition] in
            try? await composition.runHistory.markRunningAsInterrupted()
        }
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.workflows = try await self.composition.repository.loadAll()
                self.libraryError = nil
            } catch {
                self.workflows = []
                self.libraryError = "Could not load workflows: \(error.localizedDescription)"
            }
        }
    }

    func run(_ workflow: SavedWorkflow) {
        Task { [weak self] in
            guard let self else { return }
            let outcome = await self.composition.coordinator.submit(workflow.definition, source: .manual)
            switch outcome {
            case .started:
                self.isRunning = true
                self.status = "Running \(workflow.name)..."
            case .queued:
                self.isRunning = true
                self.status = "Queued \(workflow.name)"
            case .queueFull:
                self.status = "Queue is full"
            case .rejected(let message):
                self.status = "Cannot run: \(message)"
            case .suppressedDuplicate, .suppressedCooldown,
                 .suppressedPaused, .suppressedSessionNotReady:
                self.status = "Not started"
            }

            await self.monitorRun()
        }
    }

    private func monitorRun() async {
        while true {
            let snapshot = await composition.coordinator.status()
            apply(snapshot)
            if !snapshot.isRunning, snapshot.queuedCount == 0 {
                return
            }
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    func cancel() {
        Task { [weak self] in
            guard let self else { return }
            self.status = "Cancelling..."
            await self.composition.coordinator.cancelAll()
            await self.monitorRun()
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
            NotificationCenter.default.post(name: .taskOSRuntimeStateDidChange, object: nil)
        }
    }

    func refreshStatus() {
        Task { [weak self] in
            await self?.updateStatus()
        }
    }

    private func updateStatus() async {
        apply(await composition.coordinator.status())
    }

    private func apply(_ snapshot: RunCoordinatorStatus) {
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
