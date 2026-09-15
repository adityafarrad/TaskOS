import UserNotifications

enum NotificationPermission {
    @discardableResult
    static func request() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
