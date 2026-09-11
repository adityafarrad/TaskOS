import Foundation

public struct OpenApplicationAction: Codable, Hashable, Sendable {
    public var application: ResourceReference

    public init(application: ResourceReference) {
        self.application = application
    }
}

public struct HideApplicationAction: Codable, Hashable, Sendable {
    public var application: ResourceReference

    public init(application: ResourceReference) {
        self.application = application
    }
}

public struct QuitApplicationAction: Codable, Hashable, Sendable {
    public static let protectedBundleIdentifiers: Set<String> = [
        "usuals.com.TaskOS",
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.loginwindow",
        "com.apple.systemuiserver",
    ]

    public var application: ResourceReference

    public init(application: ResourceReference) {
        self.application = application
    }
}

public struct OpenWebsiteAction: Codable, Hashable, Sendable {
    public var url: String
    public var browser: ResourceReference?

    public init(url: String, browser: ResourceReference? = nil) {
        self.url = url
        self.browser = browser
    }
}

public struct ArrangeWindowAction: Codable, Hashable, Sendable {
    public var application: ResourceReference
    public var preset: WindowPreset
    public var display: WindowDisplaySelection

    public init(application: ResourceReference, preset: WindowPreset, display: WindowDisplaySelection = .current) {
        self.application = application
        self.preset = preset
        self.display = display
    }
}

public struct WaitAction: Codable, Hashable, Sendable {
    public static let allowedRange: ClosedRange<TimeInterval> = 0.1...30.0

    public var duration: TimeInterval

    public init(duration: TimeInterval) {
        self.duration = duration
    }
}

public struct ShowNotificationAction: Codable, Hashable, Sendable {
    public var title: String
    public var message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

public struct CopyTextAction: Codable, Hashable, Sendable {
    public static let maximumLength = 10_000

    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public enum ActionConfiguration: Codable, Hashable, Sendable {
    case openApplication(OpenApplicationAction)
    case hideApplication(HideApplicationAction)
    case quitApplication(QuitApplicationAction)
    case openWebsite(OpenWebsiteAction)
    case arrangeWindow(ArrangeWindowAction)
    case wait(WaitAction)
    case showNotification(ShowNotificationAction)
    case copyText(CopyTextAction)

    public var id: ActionID {
        switch self {
        case .openApplication:
            return .openApplication
        case .hideApplication:
            return .hideApplication
        case .quitApplication:
            return .quitApplication
        case .openWebsite:
            return .openWebsite
        case .arrangeWindow:
            return .arrangeWindow
        case .wait:
            return .wait
        case .showNotification:
            return .showNotification
        case .copyText:
            return .copyText
        }
    }
}
