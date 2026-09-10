import Foundation

public struct OpenApplicationAction: Codable, Hashable, Sendable {
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

public enum ActionConfiguration: Codable, Hashable, Sendable {
    case openApplication(OpenApplicationAction)
    case openWebsite(OpenWebsiteAction)
    case wait(WaitAction)
    case showNotification(ShowNotificationAction)

    public var id: ActionID {
        switch self {
        case .openApplication:
            return .openApplication
        case .openWebsite:
            return .openWebsite
        case .wait:
            return .wait
        case .showNotification:
            return .showNotification
        }
    }
}
