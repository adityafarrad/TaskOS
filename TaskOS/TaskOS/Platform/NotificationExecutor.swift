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
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            break
        case .denied:
            return .failed(ActionFailure(message: "Notifications are off for TaskOS. Enable them in System Settings > Notifications > TaskOS."))
        case .notDetermined:
            return .failed(ActionFailure(message: "Notification permission has not been granted yet. Test this workflow from the editor first."))
        @unknown default:
            return .failed(ActionFailure(message: "Notification permission is unavailable."))
        }

        let content = UNMutableNotificationContent()
        content.title = configuration.title
        content.body = configuration.message

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
            return .succeeded
        } catch {
            return .failed(ActionFailure(message: "Notification failed. Check the title and message, then try again."))
        }
    }
}
