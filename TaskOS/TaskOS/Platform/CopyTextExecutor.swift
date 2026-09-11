import AppKit
import TaskOSCore

struct CopyTextExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .copyText }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .copyText(let configuration) = action else {
            return .failed(ActionFailure(message: "Copy Text received an unsupported action."))
        }
        return await write(configuration.text)
    }

    @MainActor
    private func write(_ value: String) -> ActionOutcome {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.setString(value, forType: .string) {
            return .succeeded
        }
        return .failed(ActionFailure(message: "Could not write to the clipboard."))
    }
}
