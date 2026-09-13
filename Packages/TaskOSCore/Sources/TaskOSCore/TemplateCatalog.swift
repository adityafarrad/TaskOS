import Foundation

public enum TemplateParameter: String, Hashable, Sendable {
    case application
    case file
    case website
    case display
    case text
    case percentage
}

public struct AutomationTemplate: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let summary: String
    public let trigger: ComposerTriggerDraft
    public let actions: [ComposerActionDraft]
    public let requiredParameters: [TemplateParameter]
    public let limitations: String?

    public init(
        id: String,
        name: String,
        summary: String,
        trigger: ComposerTriggerDraft,
        actions: [ComposerActionDraft],
        requiredParameters: [TemplateParameter],
        limitations: String? = nil
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.trigger = trigger
        self.actions = actions
        self.requiredParameters = requiredParameters
        self.limitations = limitations
    }

    public func document() -> ComposerDocument {
        ComposerDocument(trigger: trigger, actions: actions)
    }
}

public extension ComposerActionDraft {
    var actionID: ActionID {
        switch self {
        case .openApplication: return .openApplication
        case .hideApplication: return .hideApplication
        case .quitApplication: return .quitApplication
        case .openFile: return .openFile
        case .revealInFinder: return .revealInFinder
        case .openWebsite: return .openWebsite
        case .arrangeWindow: return .arrangeWindow
        case .wait: return .wait
        case .showNotification: return .showNotification
        case .copyText: return .copyText
        }
    }
}

public extension ComposerTriggerDraft {
    var triggerID: TriggerID {
        switch self {
        case .manual: return .manual
        case .daily, .weekdays, .interval, .relative, .once, .oneTime: return .schedule
        case .applicationLifecycle: return .applicationLifecycle
        case .wake: return .wake
        case .displayConnection: return .displayConnection
        case .externalVolume: return .externalVolume
        case .powerSource: return .powerSource
        case .batteryThreshold: return .batteryThreshold
        }
    }
}

public struct TemplateCatalog: Sendable {
    public let templates: [AutomationTemplate]

    public init(templates: [AutomationTemplate]) {
        self.templates = templates
    }

    public func template(id: String) -> AutomationTemplate? {
        templates.first { $0.id == id }
    }

    public static let standard = TemplateCatalog(templates: [
        AutomationTemplate(
            id: "workday",
            name: "Start my workday",
            summary: "Every day at 9:00, open Mail and Calendar side by side.",
            trigger: .daily(hour: 9, minute: 0),
            actions: [
                .openApplication(name: "Mail", resolved: nil),
                .openApplication(name: "Calendar", resolved: nil),
                .arrangeWindow(name: "Mail", resolved: nil, preset: .leftHalf, display: .current),
                .arrangeWindow(name: "Calendar", resolved: nil, preset: .rightHalf, display: .current),
            ],
            requiredParameters: [.application]
        ),
        AutomationTemplate(
            id: "study",
            name: "Open my study workspace",
            summary: "Open Safari and Notes on the left and right halves.",
            trigger: .manual,
            actions: [
                .openApplication(name: "Safari", resolved: nil),
                .openApplication(name: "Notes", resolved: nil),
                .arrangeWindow(name: "Safari", resolved: nil, preset: .leftHalf, display: .current),
                .arrangeWindow(name: "Notes", resolved: nil, preset: .rightHalf, display: .current),
            ],
            requiredParameters: [.application]
        ),
        AutomationTemplate(
            id: "research",
            name: "Research with browser and notes side by side",
            summary: "Open a site in Safari with Notes beside it.",
            trigger: .manual,
            actions: [
                .openApplication(name: "Safari", resolved: nil),
                .openApplication(name: "Notes", resolved: nil),
                .openWebsite(url: "https://", browser: nil),
                .arrangeWindow(name: "Safari", resolved: nil, preset: .leftHalf, display: .current),
                .arrangeWindow(name: "Notes", resolved: nil, preset: .rightHalf, display: .current),
            ],
            requiredParameters: [.application, .website]
        ),
        AutomationTemplate(
            id: "writing",
            name: "Open a writing workspace and hide distractions",
            summary: "Open TextEdit, then hide Mail and Safari. This does not change Focus settings.",
            trigger: .manual,
            actions: [
                .openApplication(name: "TextEdit", resolved: nil),
                .hideApplication(name: "Mail", resolved: nil),
                .hideApplication(name: "Safari", resolved: nil),
            ],
            requiredParameters: [.application],
            limitations: "Hides windows; it does not enable a macOS Focus mode."
        ),
        AutomationTemplate(
            id: "meeting",
            name: "Open meeting materials",
            summary: "Open a selected file or folder, then a meeting link. It does not join a meeting.",
            trigger: .manual,
            actions: [
                .openFile(target: nil),
                .openWebsite(url: "https://", browser: nil),
            ],
            requiredParameters: [.file, .website],
            limitations: "TaskOS does not detect or join meetings."
        ),
        AutomationTemplate(
            id: "weekday",
            name: "Start a weekday routine",
            summary: "Every weekday at 9:00, open Mail and Calendar.",
            trigger: .weekdays(Weekday.weekdays, hour: 9, minute: 0),
            actions: [
                .openApplication(name: "Mail", resolved: nil),
                .openApplication(name: "Calendar", resolved: nil),
            ],
            requiredParameters: [.application]
        ),
        AutomationTemplate(
            id: "break",
            name: "Show a recurring break reminder",
            summary: "Every day at 2:00 PM, show a reminder to take a break.",
            trigger: .daily(hour: 14, minute: 0),
            actions: [
                .showNotification(title: "Break time", message: "Stand up and stretch."),
            ],
            requiredParameters: []
        ),
        AutomationTemplate(
            id: "external-display",
            name: "Arrange my external-display workspace",
            summary: "When an external display connects, open Safari on the left half.",
            trigger: .displayConnection(event: .connected, selection: .anyExternal),
            actions: [
                .openApplication(name: "Safari", resolved: nil),
                .arrangeWindow(name: "Safari", resolved: nil, preset: .leftHalf, display: .current),
            ],
            requiredParameters: [.application]
        ),
        AutomationTemplate(
            id: "return-main",
            name: "Return my workspace to the main display",
            summary: "When a display disconnects, maximize Safari on the main display.",
            trigger: .displayConnection(event: .disconnected, selection: .anyExternal),
            actions: [
                .arrangeWindow(name: "Safari", resolved: nil, preset: .maximize, display: .main),
            ],
            requiredParameters: [.application, .display]
        ),
        AutomationTemplate(
            id: "drive-folder",
            name: "Open a folder when my external drive mounts",
            summary: "When an external drive mounts, open a selected folder.",
            trigger: .externalVolume(event: .mounted, selection: .anyExternal),
            actions: [
                .openFile(target: nil),
            ],
            requiredParameters: [.file]
        ),
        AutomationTemplate(
            id: "battery",
            name: "Notify me at a battery threshold",
            summary: "When the battery drops below 20%, show a notification.",
            trigger: .batteryThreshold(comparator: .below, percentage: 20),
            actions: [
                .showNotification(title: "Battery low", message: "Plug in your charger."),
            ],
            requiredParameters: [.percentage]
        ),
        AutomationTemplate(
            id: "agenda",
            name: "Copy my meeting agenda or checklist",
            summary: "Replacing the clipboard with a reusable checklist.",
            trigger: .manual,
            actions: [
                .copyText("Meeting agenda:\n- Review blockers\n- Next steps"),
            ],
            requiredParameters: [.text]
        ),
    ])
}
