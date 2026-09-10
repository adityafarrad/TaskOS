import Foundation

public enum CanonicalPhrase {
    public static func text(for action: ActionConfiguration) -> String {
        switch action {
        case .openApplication(let configuration):
            return "Open \(configuration.application.label)"
        case .openWebsite(let configuration):
            return "Open \(configuration.url)"
        case .arrangeWindow(let configuration):
            return text(for: configuration)
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

    public static func text(for configuration: ArrangeWindowAction) -> String {
        switch configuration.preset {
        case .maximize:
            return "Maximize \(configuration.application.label)"
        case .center:
            return "Center \(configuration.application.label)"
        default:
            return "Put \(configuration.application.label) \(configuration.preset.phraseSuffix)"
        }
    }

    public static func durationText(_ value: TimeInterval) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
