import Foundation

public struct CapabilityGuide: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case trigger
        case action
    }

    public let id: String
    public let kind: Kind
    public let title: String
    public let whatItDoes: String
    public let example: String
    public let parameters: [String]
    public let permissions: [PermissionKind]
    public let limitations: String?
    public let hardwareRequirement: String?

    public init(
        id: String,
        kind: Kind,
        title: String,
        whatItDoes: String,
        example: String,
        parameters: [String],
        permissions: [PermissionKind],
        limitations: String? = nil,
        hardwareRequirement: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.whatItDoes = whatItDoes
        self.example = example
        self.parameters = parameters
        self.permissions = permissions
        self.limitations = limitations
        self.hardwareRequirement = hardwareRequirement
    }
}

public enum CapabilityGuideCatalog {
    public static let standard: [CapabilityGuide] = triggerGuides + actionGuides

    public static let triggerGuides: [CapabilityGuide] = [
        CapabilityGuide(
            id: "trigger.manual",
            kind: .trigger,
            title: "Manual",
            whatItDoes: "Run the workflow from the app or the menu bar.",
            example: "Manually open Safari and Notes",
            parameters: [],
            permissions: []
        ),
        CapabilityGuide(
            id: "trigger.schedule",
            kind: .trigger,
            title: "Schedule",
            whatItDoes: "Run once, daily, on selected weekdays, or on a fixed interval.",
            example: "Every weekday at 9 am open Safari",
            parameters: ["Time or interval", "Weekdays"],
            permissions: [],
            limitations: "Missed occurrences are skipped, and a repeated daylight-saving time runs once."
        ),
        CapabilityGuide(
            id: "trigger.applicationLifecycle",
            kind: .trigger,
            title: "Application lifecycle",
            whatItDoes: "Run when a selected application launches or quits.",
            example: "When Safari opens, show a notification",
            parameters: ["Application", "Opens or quits"],
            permissions: [],
            limitations: "MacFlow's own open and quit actions are suppressed to avoid loops."
        ),
        CapabilityGuide(
            id: "trigger.wake",
            kind: .trigger,
            title: "Mac wakes",
            whatItDoes: "Run after the Mac wakes, once the session is ready.",
            example: "When the Mac wakes, show a notification",
            parameters: [],
            permissions: [],
            limitations: "A genuine wake is required; MacFlow does not wake the Mac."
        ),
        CapabilityGuide(
            id: "trigger.displayConnection",
            kind: .trigger,
            title: "Display connection",
            whatItDoes: "Run when a display connects or disconnects.",
            example: "When a display connects, arrange Safari on the left half",
            parameters: ["Connects or disconnects", "Any external or a specific display"],
            permissions: [],
            limitations: "Specific display identity is per session.",
            hardwareRequirement: "An external display"
        ),
        CapabilityGuide(
            id: "trigger.externalVolume",
            kind: .trigger,
            title: "External volume",
            whatItDoes: "Run when an external storage volume mounts or unmounts.",
            example: "When an external drive mounts, open a folder",
            parameters: ["Mounts or unmounts", "Any external drive"],
            permissions: [],
            limitations: "External storage only, not general USB devices.",
            hardwareRequirement: "Removable storage"
        ),
        CapabilityGuide(
            id: "trigger.powerSource",
            kind: .trigger,
            title: "Power source",
            whatItDoes: "Run when the Mac switches between battery and external power.",
            example: "When the Mac switches to battery, show a notification",
            parameters: ["To battery or to power"],
            permissions: []
        ),
        CapabilityGuide(
            id: "trigger.batteryThreshold",
            kind: .trigger,
            title: "Battery threshold",
            whatItDoes: "Run when the battery crosses above or below a percentage.",
            example: "When the battery drops below 20%, show a notification",
            parameters: ["Above or below", "Percentage"],
            permissions: [],
            limitations: "Rearms with a two-point margin to avoid repeated firing.",
            hardwareRequirement: "A built-in battery"
        ),
    ]

    public static let actionGuides: [CapabilityGuide] = [
        CapabilityGuide(
            id: "action.openApplication",
            kind: .action,
            title: "Open Application",
            whatItDoes: "Launch the selected app if needed, then activate it.",
            example: "Open Safari",
            parameters: ["Application"],
            permissions: [],
            limitations: "Fails clearly if the app is not installed."
        ),
        CapabilityGuide(
            id: "action.hideApplication",
            kind: .action,
            title: "Hide Application",
            whatItDoes: "Hide a selected running app.",
            example: "Hide Mail",
            parameters: ["Application"],
            permissions: [],
            limitations: "Only affects an app that is running."
        ),
        CapabilityGuide(
            id: "action.quitApplication",
            kind: .action,
            title: "Quit Application",
            whatItDoes: "Request a normal quit of a selected running app.",
            example: "Quit Safari",
            parameters: ["Application"],
            permissions: [],
            limitations: "Never force quits; may wait on a dialog. Cannot quit TaskOS, Finder, or system infrastructure."
        ),
        CapabilityGuide(
            id: "action.openFile",
            kind: .action,
            title: "Open File or Folder",
            whatItDoes: "Open an explicitly selected document or folder.",
            example: "Open the selected file",
            parameters: ["Selected file or folder"],
            permissions: [],
            limitations: "Rejects applications, installers, scripts, and automation files."
        ),
        CapabilityGuide(
            id: "action.revealInFinder",
            kind: .action,
            title: "Reveal in Finder",
            whatItDoes: "Reveal an explicitly selected item in Finder.",
            example: "Reveal the selected item",
            parameters: ["Selected item"],
            permissions: []
        ),
        CapabilityGuide(
            id: "action.openWebsite",
            kind: .action,
            title: "Open Website",
            whatItDoes: "Open an absolute HTTP(S) URL in the default or a selected browser.",
            example: "Open apple.com",
            parameters: ["Web address", "Browser (optional)"],
            permissions: [],
            limitations: "HTTP(S) only; the browser card value is not part of the command text."
        ),
        CapabilityGuide(
            id: "action.arrangeWindow",
            kind: .action,
            title: "Arrange Window",
            whatItDoes: "Position a selected app's window using a preset and display.",
            example: "Put Safari on the left half",
            parameters: ["Application", "Position", "Display"],
            permissions: [.accessibility],
            limitations: "Needs Accessibility permission; ambiguous multi-window cases fail clearly."
        ),
        CapabilityGuide(
            id: "action.wait",
            kind: .action,
            title: "Wait",
            whatItDoes: "Pause between actions.",
            example: "Wait 5 seconds",
            parameters: ["Duration"],
            permissions: [],
            limitations: "0.1 to 30 seconds; cumulative waits are capped at 60 seconds."
        ),
        CapabilityGuide(
            id: "action.showNotification",
            kind: .action,
            title: "Show Notification",
            whatItDoes: "Submit a notification with a configured title and message.",
            example: "Show a notification",
            parameters: ["Title", "Message"],
            permissions: [.notifications],
            limitations: "Success means macOS accepted the request, not that it was seen."
        ),
        CapabilityGuide(
            id: "action.copyText",
            kind: .action,
            title: "Copy Text",
            whatItDoes: "Replace the clipboard with configured literal text.",
            example: "Copy \"meeting agenda\"",
            parameters: ["Text"],
            permissions: [],
            limitations: "Replaces clipboard contents; MacFlow never reads the clipboard."
        ),
    ]
}
