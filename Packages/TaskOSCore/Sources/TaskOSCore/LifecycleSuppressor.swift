import Foundation

public actor LifecycleSuppressor {
    private let clock: CoreClock
    public let window: TimeInterval
    private var suppressedUntil: [String: Date] = [:]

    public init(clock: CoreClock, window: TimeInterval = 3) {
        self.clock = clock
        self.window = window
    }

    public func suppress(bundleIdentifier: String) {
        guard !bundleIdentifier.isEmpty else { return }
        suppressedUntil[bundleIdentifier] = clock.now().addingTimeInterval(window)
    }

    public func isSuppressed(bundleIdentifier: String, at date: Date? = nil) -> Bool {
        let now = date ?? clock.now()
        guard let deadline = suppressedUntil[bundleIdentifier] else { return false }
        if deadline <= now {
            suppressedUntil.removeValue(forKey: bundleIdentifier)
            return false
        }
        return true
    }

    public func clear() {
        suppressedUntil.removeAll()
    }
}
