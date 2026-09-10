import Foundation

public protocol ActionExecutor: Sendable {
    var supportedID: ActionID { get }
    func execute(_ action: ActionConfiguration) async -> ActionOutcome
}
