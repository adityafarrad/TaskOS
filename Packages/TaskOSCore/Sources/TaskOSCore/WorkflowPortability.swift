import Foundation

public enum PortabilityError: Error, Equatable {
    case tooLarge
    case unsupportedFormat(found: Int, supported: Int)
    case malformed(String)
}

public enum WorkflowPortability {
    public static let formatVersion = 1
    public static let maximumBytes = 256 * 1024

    public static func export(_ definition: AutomationDefinition) throws -> Data {
        let portable = PortableWorkflow(definition: definition)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(portable)
    }

    public static func importWorkflow(
        _ data: Data,
        id: AutomationID = AutomationID()
    ) throws -> AutomationDefinition {
        guard data.count <= maximumBytes else {
            throw PortabilityError.tooLarge
        }

        struct Probe: Codable {
            let formatVersion: Int
        }

        let decoder = JSONDecoder()
        let probe: Probe
        do {
            probe = try decoder.decode(Probe.self, from: data)
        } catch {
            throw PortabilityError.malformed(error.localizedDescription)
        }

        guard probe.formatVersion <= formatVersion else {
            throw PortabilityError.unsupportedFormat(found: probe.formatVersion, supported: formatVersion)
        }

        do {
            let portable = try decoder.decode(PortableWorkflow.self, from: data)
            return portable.makeDefinition(id: id)
        } catch {
            throw PortabilityError.malformed(error.localizedDescription)
        }
    }
}

private struct PortableWorkflow: Codable {
    let formatVersion: Int
    let name: String
    let trigger: TriggerConfiguration
    let actions: [PortableAction]

    init(definition: AutomationDefinition) {
        self.formatVersion = WorkflowPortability.formatVersion
        self.name = definition.name
        self.trigger = definition.trigger
        self.actions = definition.actions.map(PortableAction.init)
    }

    func makeDefinition(id: AutomationID) -> AutomationDefinition {
        AutomationDefinition(
            id: id,
            name: name,
            revision: WorkflowRevision(1),
            trigger: trigger,
            actions: actions.map { $0.makeAction() }
        )
    }
}

private enum PortableAction: Codable {
    case openApplication(label: String)
    case hideApplication(label: String)
    case quitApplication(label: String)
    case openFile(kind: FileTarget.Kind, label: String)
    case revealInFinder(kind: FileTarget.Kind, label: String)
    case openWebsite(url: String, browserLabel: String?)
    case arrangeWindow(label: String, preset: WindowPreset, display: WindowDisplaySelection)
    case wait(duration: TimeInterval)
    case showNotification(title: String, message: String)
    case copyText(text: String)

    init(_ action: ActionConfiguration) {
        switch action {
        case .openApplication(let value):
            self = .openApplication(label: value.application.label)
        case .hideApplication(let value):
            self = .hideApplication(label: value.application.label)
        case .quitApplication(let value):
            self = .quitApplication(label: value.application.label)
        case .openFile(let value):
            self = .openFile(kind: value.target.kind, label: value.target.displayName)
        case .revealInFinder(let value):
            self = .revealInFinder(kind: value.target.kind, label: value.target.displayName)
        case .openWebsite(let value):
            self = .openWebsite(url: value.url, browserLabel: value.browser?.label)
        case .arrangeWindow(let value):
            self = .arrangeWindow(label: value.application.label, preset: value.preset, display: value.display)
        case .wait(let value):
            self = .wait(duration: value.duration)
        case .showNotification(let value):
            self = .showNotification(title: value.title, message: value.message)
        case .copyText(let value):
            self = .copyText(text: value.text)
        }
    }

    private static func portableDisplay(_ display: WindowDisplaySelection) -> WindowDisplaySelection {
        if case .display = display {
            return .current
        }
        return display
    }

    func makeAction() -> ActionConfiguration {
        switch self {
        case .openApplication(let label):
            return .openApplication(OpenApplicationAction(application: .application(bundleIdentifier: "", label: label)))
        case .hideApplication(let label):
            return .hideApplication(HideApplicationAction(application: .application(bundleIdentifier: "", label: label)))
        case .quitApplication(let label):
            return .quitApplication(QuitApplicationAction(application: .application(bundleIdentifier: "", label: label)))
        case .openFile(let kind, let label):
            return .openFile(OpenFileAction(target: FileTarget(kind: kind, displayName: label, path: "")))
        case .revealInFinder(let kind, let label):
            return .revealInFinder(RevealInFinderAction(target: FileTarget(kind: kind, displayName: label, path: "")))
        case .openWebsite(let url, let browserLabel):
            let browser = browserLabel.map { ResourceReference.application(bundleIdentifier: "", label: $0) }
            return .openWebsite(OpenWebsiteAction(url: url, browser: browser))
        case .arrangeWindow(let label, let preset, let display):
            return .arrangeWindow(
                ArrangeWindowAction(
                    application: .application(bundleIdentifier: "", label: label),
                    preset: preset,
                    display: Self.portableDisplay(display)
                )
            )
        case .wait(let duration):
            return .wait(WaitAction(duration: duration))
        case .showNotification(let title, let message):
            return .showNotification(ShowNotificationAction(title: title, message: message))
        case .copyText(let text):
            return .copyText(CopyTextAction(text: text))
        }
    }
}
