import AppKit
import TaskOSCore

struct HideApplicationExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .hideApplication }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .hideApplication(let configuration) = action else {
            return .failed(ActionFailure(message: "Hide Application received an unsupported action."))
        }
        return await hide(
            bundleIdentifier: configuration.application.identifier,
            label: configuration.application.label
        )
    }

    @MainActor
    private func hide(bundleIdentifier: String, label: String) async -> ActionOutcome {
        guard let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return .failed(ActionFailure(message: "\(label) is not running."))
        }
        if application.hide() {
            return .succeeded
        }
        return .failed(ActionFailure(message: "Could not hide \(label)."))
    }
}
