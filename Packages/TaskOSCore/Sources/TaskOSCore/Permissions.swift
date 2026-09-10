import Foundation

public enum PermissionKind: String, Codable, Sendable, CaseIterable, Hashable {
    case notifications
    case accessibility
}

public enum PermissionState: String, Codable, Sendable, Hashable {
    case notDetermined
    case granted
    case denied
}

public protocol PermissionStatusProvider: Sendable {
    func state(for permission: PermissionKind) async -> PermissionState
}

extension ActionConfiguration {
    public var requiredPermissions: Set<PermissionKind> {
        switch self {
        case .openApplication, .wait:
            return []
        case .showNotification:
            return [.notifications]
        }
    }
}
