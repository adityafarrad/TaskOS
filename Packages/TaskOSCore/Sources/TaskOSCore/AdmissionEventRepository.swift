import Foundation

public protocol AdmissionEventSink: Sendable {
    func record(_ event: AdmissionEvent) async
}

public protocol AdmissionEventRepository: AdmissionEventSink {
    func recentEvents(limit: Int) async throws -> [AdmissionEvent]
    func deleteAll(for automationID: AutomationID) async throws
    func clear() async throws
}

public enum AdmissionEventRetention {
    public static let maximumEvents = 200
    public static let maximumAge: TimeInterval = 30 * 24 * 60 * 60
}
