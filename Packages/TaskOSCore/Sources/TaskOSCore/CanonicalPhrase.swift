import Foundation

public enum CanonicalPhrase {
    public static func text(
        for action: ActionConfiguration,
        language: CommandLanguageCatalog = .standard
    ) -> String {
        switch action {
        case .openApplication(let configuration):
            return language.canonicalActionTemplate(.openApplication)?
                .render(["application": language.applicationPhrase(configuration.application.label)])
                ?? "Open \(configuration.application.label)"
        case .hideApplication(let configuration):
            return language.canonicalActionTemplate(.hideApplication)?
                .render(["application": language.applicationPhrase(configuration.application.label)])
                ?? "Hide \(configuration.application.label)"
        case .quitApplication(let configuration):
            return language.canonicalActionTemplate(.quitApplication)?
                .render(["application": language.applicationPhrase(configuration.application.label)])
                ?? "Quit \(configuration.application.label)"
        case .openFile(let configuration):
            let variant = configuration.target.kind == .folder ? "folder" : "file"
            return language.canonicalActionTemplate(.openFile, variant: variant)?.render()
                ?? (configuration.target.kind == .folder ? "Open the selected folder" : "Open the selected file")
        case .revealInFinder:
            return language.canonicalActionTemplate(.revealInFinder)?.render()
                ?? "Reveal the selected item"
        case .openWebsite(let configuration):
            return language.canonicalActionTemplate(.openWebsite)?
                .render(["url": configuration.url])
                ?? "Open \(configuration.url)"
        case .arrangeWindow(let configuration):
            return text(for: configuration, language: language)
        case .wait(let wait):
            return language.canonicalActionTemplate(.wait)?
                .render(["duration": durationText(wait.duration)])
                ?? "Wait \(durationText(wait.duration)) seconds"
        case .showNotification:
            return language.canonicalActionTemplate(.showNotification)?.render()
                ?? "Show a notification"
        case .copyText(let copy):
            return language.canonicalActionTemplate(.copyText)?
                .render(["text": copy.text])
                ?? "Copy \"\(copy.text)\""
        }
    }

    public static func text(
        for trigger: TriggerConfiguration,
        language: CommandLanguageCatalog = .standard
    ) -> String {
        switch trigger {
        case .manual:
            return language.canonicalTriggerTemplate(.manual)?.render() ?? "Manually"
        case .schedule(let schedule):
            return text(for: schedule, language: language)
        case .applicationLifecycle(let trigger):
            return language.canonicalTriggerTemplate(.applicationLifecycle)?
                .render([
                    "application": trigger.application.label,
                    "event": trigger.event.displayName,
                ])
                ?? "When \(trigger.application.label) \(trigger.event.displayName)"
        case .wake:
            return language.canonicalTriggerTemplate(.wake)?.render() ?? "When the Mac wakes"
        case .displayConnection(let trigger):
            let noun = trigger.selection == .anyExternal ? "an external display" : trigger.selection.displayName
            let variant = trigger.event == .connected ? "connected" : "disconnected"
            return language.canonicalTriggerTemplate(.displayConnection, variant: variant)?
                .render(["display": noun])
                ?? (trigger.event == .connected ? "When \(noun) connects" : "When \(noun) disconnects")
        case .externalVolume(let trigger):
            let noun = trigger.selection == .anyExternal ? "an external drive" : trigger.selection.displayName
            let variant = trigger.event == .mounted ? "mounted" : "unmounted"
            return language.canonicalTriggerTemplate(.externalVolume, variant: variant)?
                .render(["volume": noun])
                ?? (trigger.event == .mounted ? "When \(noun) mounts" : "When \(noun) unmounts")
        case .powerSource(let trigger):
            return language.canonicalTriggerTemplate(.powerSource)?
                .render(["event": trigger.event.displayName])
                ?? "When the Mac \(trigger.event.displayName)"
        case .batteryThreshold(let trigger):
            let direction = language.trigger.batteryDirectionWords[trigger.comparator]
                ?? (trigger.comparator == .below ? "drops below" : "rises above")
            return language.canonicalTriggerTemplate(.batteryThreshold)?
                .render(["direction": direction, "percentage": "\(trigger.percentage)"])
                ?? "When the battery \(direction) \(trigger.percentage)%"
        }
    }

    public static func text(
        for schedule: ScheduleTrigger,
        language: CommandLanguageCatalog = .standard
    ) -> String {
        switch schedule {
        case .oneTime(let date):
            return language.scheduleTemplate("oneTime")?
                .render(["date": language.absoluteDateTimeText(date)])
                ?? "Once on \(language.absoluteDateTimeText(date))"
        case .daily(let hour, let minute):
            return language.scheduleTemplate("daily")?
                .render(["clock": language.clockText(hour: hour, minute: minute)])
                ?? "Every day at \(language.clockText(hour: hour, minute: minute))"
        case .weekdays(let days, let hour, let minute):
            let names = days.sorted { $0.rawValue < $1.rawValue }.map(\.displayName).joined(separator: ", ")
            return language.scheduleTemplate("weekdays")?
                .render(["days": names, "clock": language.clockText(hour: hour, minute: minute)])
                ?? "Every \(names) at \(language.clockText(hour: hour, minute: minute))"
        case .interval(let every, _):
            return language.scheduleTemplate("interval")?
                .render(["interval": language.intervalText(every)])
                ?? "Every \(language.intervalText(every))"
        }
    }

    public static func clockText(hour: Int, minute: Int) -> String {
        CommandLanguageCatalog.standard.clockText(hour: hour, minute: minute)
    }

    public static func command(
        for actions: [ActionConfiguration],
        language: CommandLanguageCatalog = .standard
    ) -> String {
        actions.map { text(for: $0, language: language) }
            .joined(separator: language.shared.actionJoiner)
    }

    public static func text(
        for configuration: ArrangeWindowAction,
        language: CommandLanguageCatalog = .standard
    ) -> String {
        switch configuration.preset {
        case .maximize:
            return language.canonicalActionTemplate(.arrangeWindow, variant: "maximize")?
                .render(["application": language.applicationPhrase(configuration.application.label)])
                ?? "Maximize \(configuration.application.label)"
        case .center:
            return language.canonicalActionTemplate(.arrangeWindow, variant: "center")?
                .render(["application": language.applicationPhrase(configuration.application.label)])
                ?? "Center \(configuration.application.label)"
        default:
            return language.canonicalActionTemplate(.arrangeWindow)?
                .render([
                    "application": language.applicationPhrase(configuration.application.label),
                    "preset": language.arrangePresetPhrase(configuration.preset),
                ])
                ?? "Put \(configuration.application.label) \(language.arrangePresetPhrase(configuration.preset))"
        }
    }

    public static func durationText(_ value: TimeInterval) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
