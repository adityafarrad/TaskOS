import Foundation

public struct CapabilityDescriptor: Hashable, Sendable {
    public let title: String
    public let summary: String

    public init(title: String, summary: String) {
        self.title = title
        self.summary = summary
    }
}

public struct CapabilityRegistry: Sendable {
    public let triggers: [TriggerID: CapabilityDescriptor]
    public let actions: [ActionID: CapabilityDescriptor]

    public init(
        triggers: [TriggerID: CapabilityDescriptor],
        actions: [ActionID: CapabilityDescriptor]
    ) {
        self.triggers = triggers
        self.actions = actions
    }

    public func descriptor(for id: TriggerID) -> CapabilityDescriptor? {
        triggers[id]
    }

    public func descriptor(for id: ActionID) -> CapabilityDescriptor? {
        actions[id]
    }

    public func consistencyIssues() -> [String] {
        var issues: [String] = []

        for id in TriggerID.allCases where triggers[id] == nil {
            issues.append("Missing trigger descriptor for '\(id.stableID)'.")
        }
        for id in ActionID.allCases where actions[id] == nil {
            issues.append("Missing action descriptor for '\(id.stableID)'.")
        }
        for key in triggers.keys where !TriggerID.allCases.contains(key) {
            issues.append("Unregistered trigger descriptor '\(key.stableID)'.")
        }
        for key in actions.keys where !ActionID.allCases.contains(key) {
            issues.append("Unregistered action descriptor '\(key.stableID)'.")
        }

        return issues.sorted()
    }

    public static let standard = CapabilityRegistry(
        triggers: [
            .manual: CapabilityDescriptor(
                title: "Manual",
                summary: "Run the workflow from the app or menu bar."
            ),
            .schedule: CapabilityDescriptor(
                title: "Schedule",
                summary: "Run once, daily, on selected weekdays, or on a fixed interval."
            ),
        ],
        actions: [
            .openApplication: CapabilityDescriptor(
                title: "Open Application",
                summary: "Launch the selected app if necessary, then activate it."
            ),
            .hideApplication: CapabilityDescriptor(
                title: "Hide Application",
                summary: "Hide a selected running app."
            ),
            .quitApplication: CapabilityDescriptor(
                title: "Quit Application",
                summary: "Request a normal quit of a selected running app."
            ),
            .openWebsite: CapabilityDescriptor(
                title: "Open Website",
                summary: "Open an absolute HTTP(S) URL in the default or a selected browser."
            ),
            .arrangeWindow: CapabilityDescriptor(
                title: "Arrange Window",
                summary: "Position a selected app's window using a preset and display selection."
            ),
            .wait: CapabilityDescriptor(
                title: "Wait",
                summary: "Pause for an explicit duration between 0.1 and 30 seconds."
            ),
            .showNotification: CapabilityDescriptor(
                title: "Show Notification",
                summary: "Submit a notification with a configured title and message."
            ),
            .copyText: CapabilityDescriptor(
                title: "Copy Text",
                summary: "Replace the clipboard with configured literal text."
            ),
        ]
    )
}
