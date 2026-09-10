import Foundation

public enum CanonicalPhrase {
    public static func text(for action: ActionConfiguration) -> String {
        switch action {
        case .openApplication(let configuration):
            return "Open \(configuration.application.label)"
        case .wait(let wait):
            return "Wait \(durationText(wait.duration)) seconds"
        case .showNotification:
            return "Show a notification"
        }
    }

    public static func text(for trigger: TriggerConfiguration) -> String {
        switch trigger {
        case .manual:
            return "Manually"
        }
    }

    public static func command(for actions: [ActionConfiguration]) -> String {
        actions.map(text(for:)).joined(separator: ", then ")
    }

    public static func durationText(_ value: TimeInterval) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
