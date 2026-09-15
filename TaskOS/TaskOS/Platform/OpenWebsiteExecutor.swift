import AppKit
import TaskOSCore

struct OpenWebsiteExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .openWebsite }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .openWebsite(let configuration) = action else {
            return .failed(ActionFailure(message: "Open Website received an unsupported action."))
        }
        guard let url = URL(string: configuration.url), OpenWebsiteAction.isAbsoluteHTTPURL(configuration.url) else {
            return .failed(ActionFailure(message: "Not a valid web address. Check the step and try again."))
        }
        return await open(url: url, browser: configuration.browser)
    }

    @MainActor
    private func open(url: URL, browser: ResourceReference?) async -> ActionOutcome {
        if let browser {
            guard let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.identifier) else {
                return .failed(ActionFailure(message: "Could not find \(browser.label)."))
            }

            let configuration = NSWorkspace.OpenConfiguration()
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    NSWorkspace.shared.open([url], withApplicationAt: applicationURL, configuration: configuration) { _, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
                return .succeeded
            } catch {
                return .failed(ActionFailure(message: "Could not open the link in \(browser.label)."))
            }
        }

        let opened = NSWorkspace.shared.open(url)
        return opened ? .succeeded : .failed(ActionFailure(message: "Could not open the link in the default browser."))
    }
}
