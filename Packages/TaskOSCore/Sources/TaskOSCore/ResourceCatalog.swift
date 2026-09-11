import Foundation

public struct ApplicationResource: Hashable, Sendable {
    public let bundleIdentifier: String
    public let displayName: String

    public init(bundleIdentifier: String, displayName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
    }
}

public struct DisplayResource: Hashable, Sendable {
    public let identifier: String
    public let displayName: String
    public let isMain: Bool

    public init(identifier: String, displayName: String, isMain: Bool) {
        self.identifier = identifier
        self.displayName = displayName
        self.isMain = isMain
    }
}

public protocol ResourceCatalog: Sendable {
    func application(bundleIdentifier: String) async -> ApplicationResource?
    func installedApplications() async -> [ApplicationResource]
    func display(identifier: String) async -> DisplayResource?
    func installedDisplays() async -> [DisplayResource]
    func fileExists(path: String) async -> Bool?
}

public extension ResourceCatalog {
    func installedApplications() async -> [ApplicationResource] {
        []
    }

    func installedDisplays() async -> [DisplayResource] {
        []
    }

    func display(identifier: String) async -> DisplayResource? {
        await installedDisplays().first { $0.identifier == identifier }
    }

    func fileExists(path: String) async -> Bool? {
        nil
    }
}
