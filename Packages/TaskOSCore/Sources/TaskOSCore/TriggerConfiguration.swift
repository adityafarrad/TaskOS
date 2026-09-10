import Foundation

public struct ManualTrigger: Codable, Hashable, Sendable {
    public init() {}

    public var id: TriggerID { .manual }
}

public enum TriggerConfiguration: Codable, Hashable, Sendable {
    case manual(ManualTrigger)
    case schedule(ScheduleTrigger)

    public var id: TriggerID {
        switch self {
        case .manual:
            return .manual
        case .schedule:
            return .schedule
        }
    }

    public var schedule: ScheduleTrigger? {
        guard case .schedule(let schedule) = self else { return nil }
        return schedule
    }
}
