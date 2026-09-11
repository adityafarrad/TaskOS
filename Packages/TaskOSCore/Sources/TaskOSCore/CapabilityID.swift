import Foundation

public enum TriggerID: String, Codable, Sendable, CaseIterable, Hashable {
    case manual
    case schedule

    public var stableID: String { rawValue }
}

public enum ActionID: String, Codable, Sendable, CaseIterable, Hashable {
    case openApplication
    case hideApplication
    case quitApplication
    case openFile
    case revealInFinder
    case openWebsite
    case arrangeWindow
    case wait
    case showNotification
    case copyText

    public var stableID: String { rawValue }
}
