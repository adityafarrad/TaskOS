import AppKit
import TaskOSCore

struct OpenFileExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .openFile }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .openFile(let configuration) = action else {
            return .failed(ActionFailure(message: "Open File received an unsupported action."))
        }
        return await open(configuration.target)
    }

    @MainActor
    private func open(_ target: FileTarget) -> ActionOutcome {
        guard !target.isExecutableOrUnsupported else {
            return .failed(ActionFailure(message: "TaskOS cannot open applications, installers, scripts, or automation files."))
        }
        guard let url = FileTargetResolver.url(for: target) else {
            return .failed(ActionFailure(message: "\(target.displayName) has no valid location. Choose it again."))
        }
        guard FileTargetValidation.isAllowed(url) else {
            return .failed(ActionFailure(message: "TaskOS cannot open applications, installers, scripts, or executable content."))
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failed(ActionFailure(message: "\(target.displayName) was moved or deleted. Choose it again."))
        }
        if NSWorkspace.shared.open(url) {
            return .succeeded
        }
        return .failed(ActionFailure(message: "Could not open \(target.displayName)."))
    }
}
