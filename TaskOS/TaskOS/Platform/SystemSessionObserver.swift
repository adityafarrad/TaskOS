import AppKit
import Foundation
import TaskOSCore

final class SystemSessionObserver: @unchecked Sendable {
    private nonisolated(unsafe) var tokens: [NSObjectProtocol] = []

    @MainActor
    init(coordinator: RunCoordinator) {
        let center = NSWorkspace.shared.notificationCenter
        let sleepToken = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [coordinator] _ in
            Task { await coordinator.updateSessionReadiness(false) }
        }
        let wakeToken = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [coordinator] _ in
            Task { await coordinator.updateSessionReadiness(true) }
        }
        tokens = [sleepToken, wakeToken]
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        for token in tokens {
            center.removeObserver(token)
        }
    }
}
