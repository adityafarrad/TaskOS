import Foundation

public enum CanonicalPhrase {
    public static func text(for action: ActionConfiguration) -> String {
        switch action {
        case .openApplication(let configuration):
            return "Open \(configuration.application.label)"
        case .hideApplication(let configuration):
            return "Hide \(configuration.application.label)"
        case .quitApplication(let configuration):
            return "Quit \(configuration.application.label)"
        case .openWebsite(let configuration):
            return "Open \(configuration.url)"
        case .arrangeWindow(let configuration):
            return text(for: configuration)
        case .wait(let wait):
            return "Wait \(durationText(wait.duration)) seconds"
        case .showNotification:
            return "Show a notification"
        case .copyText(let copy):
            return "Copy \"\(copy.text)\""
        }
    }

    public static func text(for trigger: TriggerConfiguration) -> String {
        switch trigger {
        case .manual:
            return "Manually"
        case .schedule(let schedule):
            return text(for: schedule)
        }
    }

    public static func text(for schedule: ScheduleTrigger) -> String {
        switch schedule {
        case .oneTime(let date):
            return "Once on \(shortDateTime(date))"
        case .daily(let hour, let minute):
            return "Every day at \(clockText(hour: hour, minute: minute))"
        case .weekdays(let days, let hour, let minute):
            let names = days.sorted { $0.rawValue < $1.rawValue }.map(\.displayName).joined(separator: ", ")
            return "Every \(names) at \(clockText(hour: hour, minute: minute))"
        case .interval(let every, _):
            return "Every \(intervalText(every))"
        }
    }

    public static func clockText(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private static func intervalText(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60
        if minutes >= 60, minutes.truncatingRemainder(dividingBy: 60) == 0 {
            return "\(Int(minutes / 60)) hours"
        }
        return "\(Int(minutes)) minutes"
    }

    private static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
