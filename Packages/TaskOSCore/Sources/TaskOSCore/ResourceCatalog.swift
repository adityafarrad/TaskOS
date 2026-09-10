import Foundation

public struct ApplicationResource: Hashable, Sendable {
    public let bundleIdentifier: String
    public let displayName: String

    public init(bundleIdentifier: String, displayName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

public protocol ResourceCatalog: Sendable {
    func application(bundleIdentifier: String) async -> ApplicationResource?
    func installedApplications() async -> [ApplicationResource]
}

public extension ResourceCatalog {
    func installedApplications() async -> [ApplicationResource] {
        []
    }
}
