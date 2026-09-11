import Foundation

public struct BatteryThresholdMonitor: Sendable {
    public static let rearmMargin = 2

    public let comparator: ThresholdComparison
    public let percentage: Int
    private var isArmed: Bool
    private var hasBaseline: Bool

    public init(comparator: ThresholdComparison, percentage: Int) {
        self.comparator = comparator
        self.percentage = percentage
        self.isArmed = false
        self.hasBaseline = false
    }

    public mutating func establishBaseline(_ value: Int?) {
        guard let value else { return }
        switch comparator {
        case .below:
            isArmed = value >= percentage
        case .above:
            isArmed = value <= percentage
        }
        hasBaseline = true
    }

    public mutating func observe(_ value: Int?) -> Bool {
        guard let value else { return false }
        guard hasBaseline else {
            establishBaseline(value)
            return false
        }

        switch comparator {
        case .below:
            if isArmed, value < percentage {
                isArmed = false
                return true
            }
            if !isArmed, value >= percentage + Self.rearmMargin {
                isArmed = true
            }
        case .above:
            if isArmed, value > percentage {
                isArmed = false
                return true
            }
            if !isArmed, value <= percentage - Self.rearmMargin {
                isArmed = true
            }
        }
        return false
    }
}
