import AppKit
import TaskOSCore

struct OpenApplicationExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .openApplication }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .openApplication(let configuration) = action else {
            return .failed(ActionFailure(message: "Open Application received an unsupported action."))
        }
        return await open(
            bundleIdentifier: configuration.application.identifier,
            label: configuration.application.label
        )
    }

    @MainActor
    private func open(bundleIdentifier: String, label: String) async -> ActionOutcome {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return .failed(ActionFailure(message: "Could not find \(label). It may not be installed."))
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NSRunningApplication, Error>) in
                NSWorkspace.shared.openApplication(at: url, configuration: configuration) { application, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let application {
                        continuation.resume(returning: application)
                    } else {
                        continuation.resume(throwing: CocoaError(.executableLoad))
                    }
                }
            }
            return .succeeded
        } catch {
            return .failed(ActionFailure(message: "Could not open \(label): \(error.localizedDescription)"))
        }
    }
}
