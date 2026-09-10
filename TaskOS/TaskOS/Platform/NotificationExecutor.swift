import Foundation
import UserNotifications
import TaskOSCore

struct NotificationExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .showNotification }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .showNotification(let configuration) = action else {
            return .failed(ActionFailure(message: "Notification received an unsupported action."))
        }

        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return .failed(ActionFailure(message: "Notification permission is off. Enable it in System Settings > Notifications > TaskOS."))
            }

            let content = UNMutableNotificationContent()
            content.title = configuration.title
            content.body = configuration.message

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            try await center.add(request)
            return .succeeded
        } catch {
            return .failed(ActionFailure(message: "Notification failed: \(error.localizedDescription)"))
        }
    }
}
