import AppKit
import TaskOSCore

struct QuitApplicationExecutor: ActionExecutor {
    let suppressor: LifecycleSuppressor?

    init(suppressor: LifecycleSuppressor? = nil) {
        self.suppressor = suppressor
    }

    nonisolated var supportedID: ActionID { .quitApplication }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .quitApplication(let configuration) = action else {
            return .failed(ActionFailure(message: "Quit Application received an unsupported action."))
        }
        await suppressor?.suppress(bundleIdentifier: configuration.application.identifier)
        let outcome = await quit(
            bundleIdentifier: configuration.application.identifier,
            label: configuration.application.label
        )
        await suppressor?.suppress(bundleIdentifier: configuration.application.identifier)
        return outcome
    }

    @MainActor
    private func quit(bundleIdentifier: String, label: String) async -> ActionOutcome {
        guard !QuitApplicationAction.protectedBundleIdentifiers.contains(bundleIdentifier) else {
            return .failed(ActionFailure(message: "TaskOS cannot quit itself, Finder, or system infrastructure."))
        }
        guard let application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return .failed(ActionFailure(message: "\(label) is not running."))
        }

        guard application.terminate() else {
            return .failed(ActionFailure(message: "Could not request a normal quit of \(label)."))
        }

        let deadline = Date().addingTimeInterval(10)
        while !application.isTerminated, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled {
                return .cancelled
            }
        }

        if application.isTerminated {
            return .succeeded
        }
        return .failed(ActionFailure(message: "\(label) did not quit. It may be waiting on a dialog; TaskOS does not force quit."))
    }
}
