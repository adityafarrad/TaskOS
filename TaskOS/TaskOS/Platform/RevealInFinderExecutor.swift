import AppKit
import TaskOSCore

struct RevealInFinderExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .revealInFinder }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .revealInFinder(let configuration) = action else {
            return .failed(ActionFailure(message: "Reveal in Finder received an unsupported action."))
        }
        return await reveal(configuration.target)
    }

    @MainActor
    private func reveal(_ target: FileTarget) -> ActionOutcome {
        guard let url = FileTargetResolver.url(for: target) else {
            return .failed(ActionFailure(message: "\(target.displayName) has no valid location. Choose it again."))
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failed(ActionFailure(message: "\(target.displayName) was moved or deleted. Choose it again."))
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        return .succeeded
    }
}
