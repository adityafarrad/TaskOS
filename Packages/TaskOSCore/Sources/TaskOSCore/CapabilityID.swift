import Foundation

public enum TriggerID: String, Codable, Sendable, CaseIterable, Hashable {
    case manual

    public var stableID: String { rawValue }
}

public enum ActionID: String, Codable, Sendable, CaseIterable, Hashable {
    case openApplication
    case wait
    case showNotification

    public var stableID: String { rawValue }
}
