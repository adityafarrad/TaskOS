import AppKit
import Foundation
import TaskOSCore

@MainActor
final class ApplicationLifecycleSource: TriggerSource {
    private var tokens: [NSObjectProtocol] = []
    private var handler: (@Sendable (ObservedTriggerEvent) -> Void)?

    nonisolated func start(_ handler: @escaping @Sendable (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID {
        await MainActor.run {
            self.handler = handler
            let center = NSWorkspace.shared.notificationCenter

            let launch = center.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let bundleIdentifier = Self.bundleIdentifier(from: notification) else { return }
                Task { @MainActor in self?.deliver(.applicationLaunched(bundleIdentifier: bundleIdentifier)) }
            }

            let terminate = center.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let bundleIdentifier = Self.bundleIdentifier(from: notification) else { return }
                Task { @MainActor in self?.deliver(.applicationQuit(bundleIdentifier: bundleIdentifier)) }
            }

            self.tokens = [launch, terminate]
        }
        return TriggerRegistrationID()
    }

    nonisolated func stop(_ id: TriggerRegistrationID) async {
        await MainActor.run {
            let center = NSWorkspace.shared.notificationCenter
            for token in self.tokens {
                center.removeObserver(token)
            }
            self.tokens = []
            self.handler = nil
        }
    }

    nonisolated private static func bundleIdentifier(from notification: Notification) -> String? {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return nil
        }
        return application.bundleIdentifier
    }

    private func deliver(_ event: ObservedTriggerEvent) {
        handler?(event)
    }
}
