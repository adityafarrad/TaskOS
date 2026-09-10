import Foundation

public struct ManualTrigger: Codable, Hashable, Sendable {
    public init() {}

    public var id: TriggerID { .manual }
}

public enum TriggerConfiguration: Codable, Hashable, Sendable {
    case manual(ManualTrigger)

    public var id: TriggerID {
        switch self {
        case .manual:
            return .manual
        }
    }
}
