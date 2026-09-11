import AppKit
import Foundation
import TaskOSCore

@MainActor
final class WakeTriggerSource: TriggerSource {
    private var token: NSObjectProtocol?
    private var handler: (@Sendable (ObservedTriggerEvent) -> Void)?

    nonisolated func start(_ handler: @escaping @Sendable (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID {
        await MainActor.run {
            self.handler = handler
            self.token = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.handler?(.woke) }
            }
        }
        return TriggerRegistrationID()
    }

    nonisolated func stop(_ id: TriggerRegistrationID) async {
        await MainActor.run {
            if let token = self.token {
                NSWorkspace.shared.notificationCenter.removeObserver(token)
            }
            self.token = nil
            self.handler = nil
        }
    }
}
