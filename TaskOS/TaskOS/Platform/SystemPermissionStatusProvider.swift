import ApplicationServices
import UserNotifications
import TaskOSCore

struct SystemPermissionStatusProvider: PermissionStatusProvider {
    nonisolated func state(for permission: PermissionKind) async -> PermissionState {
        switch permission {
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                return .granted
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
        case .accessibility:
            return AXIsProcessTrusted() ? .granted : .denied
        }
    }
}
