import Foundation

public enum LifecycleEvent: String, Codable, Hashable, Sendable {
    case launched
    case quit

    public var displayName: String {
        switch self {
        case .launched: return "opens"
        case .quit: return "quits"
        }
    }
}

public struct ApplicationLifecycleTrigger: Codable, Hashable, Sendable {
    public var application: ResourceReference
    public var event: LifecycleEvent

    public init(application: ResourceReference, event: LifecycleEvent) {
        self.application = application
        self.event = event
    }
}

public struct WakeTrigger: Codable, Hashable, Sendable {
    public init() {}
}

public enum DisplayEvent: String, Codable, Hashable, Sendable {
    case connected
    case disconnected
}

public enum DisplaySelection: Codable, Hashable, Sendable {
    case anyExternal
    case display(identifier: String, label: String)

    public var displayName: String {
        switch self {
        case .anyExternal: return "any external display"
        case .display(_, let label): return label
        }
    }
}

public struct DisplayConnectionTrigger: Codable, Hashable, Sendable {
    public var selection: DisplaySelection
    public var event: DisplayEvent

    public init(selection: DisplaySelection, event: DisplayEvent) {
        self.selection = selection
        self.event = event
    }
}

public enum VolumeEvent: String, Codable, Hashable, Sendable {
    case mounted
    case unmounted
}

public enum VolumeSelection: Codable, Hashable, Sendable {
    case anyExternal
    case volume(identifier: String, label: String)

    public var displayName: String {
        switch self {
        case .anyExternal: return "any external drive"
        case .volume(_, let label): return label
        }
    }
}

public struct ExternalVolumeTrigger: Codable, Hashable, Sendable {
    public var selection: VolumeSelection
    public var event: VolumeEvent

    public init(selection: VolumeSelection, event: VolumeEvent) {
        self.selection = selection
        self.event = event
    }
}

public enum PowerEvent: String, Codable, Hashable, Sendable {
    case toBattery
    case toExternalPower

    public var displayName: String {
        switch self {
        case .toBattery: return "switches to battery"
        case .toExternalPower: return "connects to power"
        }
    }
}

public struct PowerSourceTrigger: Codable, Hashable, Sendable {
    public var event: PowerEvent

    public init(event: PowerEvent) {
        self.event = event
    }
}

public enum ThresholdComparison: String, Codable, Hashable, Sendable {
    case above
    case below
}

public struct BatteryThresholdTrigger: Codable, Hashable, Sendable {
    public static let allowedRange: ClosedRange<Int> = 1...99

    public var comparator: ThresholdComparison
    public var percentage: Int

    public init(comparator: ThresholdComparison, percentage: Int) {
        self.comparator = comparator
        self.percentage = percentage
    }
}

public struct TriggerRegistrationID: Hashable, Sendable {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

public enum ObservedTriggerEvent: Sendable, Equatable {
    case applicationLaunched(bundleIdentifier: String)
    case applicationQuit(bundleIdentifier: String)
    case woke
    case displayConnected(identifier: String)
    case displayDisconnected(identifier: String)
    case volumeMounted(identifier: String)
    case volumeUnmounted(identifier: String)
    case powerSourceChanged(isOnExternalPower: Bool)
    case batteryChanged(percentage: Int?)
}

public protocol TriggerSource: Sendable {
    func start(_ handler: @Sendable @escaping (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID
    func stop(_ id: TriggerRegistrationID) async
}

extension TriggerConfiguration {
    public func matches(_ event: ObservedTriggerEvent) -> Bool {
        switch self {
        case .manual, .schedule, .batteryThreshold:
            return false

        case .applicationLifecycle(let trigger):
            switch (trigger.event, event) {
            case (.launched, .applicationLaunched(let identifier)),
                 (.quit, .applicationQuit(let identifier)):
                return identifier == trigger.application.identifier
            default:
                return false
            }

        case .wake:
            if case .woke = event { return true }
            return false

        case .displayConnection(let trigger):
            switch (trigger.event, event) {
            case (.connected, .displayConnected(let identifier)),
                 (.disconnected, .displayDisconnected(let identifier)):
                switch trigger.selection {
                case .anyExternal:
                    return true
                case .display(let expected, _):
                    return expected == identifier
                }
            default:
                return false
            }

        case .externalVolume(let trigger):
            switch (trigger.event, event) {
            case (.mounted, .volumeMounted(let identifier)),
                 (.unmounted, .volumeUnmounted(let identifier)):
                switch trigger.selection {
                case .anyExternal:
                    return true
                case .volume(let expected, _):
                    return expected == identifier
                }
            default:
                return false
            }

        case .powerSource(let trigger):
            guard case .powerSourceChanged(let onExternal) = event else { return false }
            return (trigger.event == .toExternalPower) == onExternal
        }
    }
}
