import AppKit
import ApplicationServices

enum AccessibilityPermission {
    @MainActor
    @discardableResult
    static func request() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        return AXIsProcessTrusted()
    }

    static var isGranted: Bool {
        AXIsProcessTrusted()
    }
}
