import Foundation

public enum TriggerID: String, Codable, Sendable, CaseIterable, Hashable {
    case manual
    case schedule
    case applicationLifecycle
    case wake
    case displayConnection
    case externalVolume
    case powerSource
    case batteryThreshold

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
