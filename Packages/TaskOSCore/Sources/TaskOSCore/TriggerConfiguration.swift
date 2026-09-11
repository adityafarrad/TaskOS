import Foundation

public struct ManualTrigger: Codable, Hashable, Sendable {
    public init() {}

    public var id: TriggerID { .manual }
}

public enum TriggerConfiguration: Codable, Hashable, Sendable {
    case manual(ManualTrigger)
    case schedule(ScheduleTrigger)
    case applicationLifecycle(ApplicationLifecycleTrigger)
    case wake(WakeTrigger)
    case displayConnection(DisplayConnectionTrigger)
    case externalVolume(ExternalVolumeTrigger)
    case powerSource(PowerSourceTrigger)
    case batteryThreshold(BatteryThresholdTrigger)

    public var id: TriggerID {
        switch self {
        case .manual:
            return .manual
        case .schedule:
            return .schedule
        case .applicationLifecycle:
            return .applicationLifecycle
        case .wake:
            return .wake
        case .displayConnection:
            return .displayConnection
        case .externalVolume:
            return .externalVolume
        case .powerSource:
            return .powerSource
        case .batteryThreshold:
            return .batteryThreshold
        }
    }

    public var schedule: ScheduleTrigger? {
        guard case .schedule(let schedule) = self else { return nil }
        return schedule
    }

    public var isEventTrigger: Bool {
        switch self {
        case .manual, .schedule:
            return false
        case .applicationLifecycle, .wake, .displayConnection,
             .externalVolume, .powerSource, .batteryThreshold:
            return true
        }
    }
}
