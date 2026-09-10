import Foundation

public struct ResourceReference: Codable, Hashable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case application
        case website
        case file
        case folder
        case display
        case volume
    }

    public let kind: Kind
    public let identifier: String
    public let label: String

    public init(kind: Kind, identifier: String, label: String) {
        self.kind = kind
        self.identifier = identifier
        self.label = label
    }

    public static func application(bundleIdentifier: String, label: String) -> ResourceReference {
        ResourceReference(kind: .application, identifier: bundleIdentifier, label: label)
    }
}
