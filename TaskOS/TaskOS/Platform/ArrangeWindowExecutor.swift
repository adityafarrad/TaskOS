import AppKit
import ApplicationServices
import TaskOSCore

struct ArrangeWindowExecutor: ActionExecutor {
    nonisolated var supportedID: ActionID { .arrangeWindow }

    nonisolated func execute(_ action: ActionConfiguration) async -> ActionOutcome {
        guard case .arrangeWindow(let configuration) = action else {
            return .failed(ActionFailure(message: "Arrange Window received an unsupported action."))
        }

        guard AXIsProcessTrusted() else {
            return .failed(
                ActionFailure(
                    message: "Accessibility permission is off for TaskOS. Enable it in System Settings > Privacy & Security > Accessibility, then try again."
                )
            )
        }

        return await arrange(configuration)
    }

    @MainActor
    private func arrange(_ configuration: ArrangeWindowAction) async -> ActionOutcome {
        guard !Task.isCancelled else { return .cancelled }
        let bundleIdentifier = configuration.application.identifier
        let label = configuration.application.label

        guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return .failed(ActionFailure(message: "\(label) is not running. Add an Open Application step before this one."))
        }

        let axApplication = AXUIElementCreateApplication(running.processIdentifier)

        guard let window = await waitForWindow(of: axApplication) else {
            if Task.isCancelled {
                return .cancelled
            }
            return .failed(ActionFailure(message: "No unambiguous window found for \(label). Make sure it is open and has a visible window."))
        }

        guard let current = frame(of: window) else {
            return .failed(ActionFailure(message: "Could not read the window position for \(label)."))
        }

        guard let usable = usableFrame(for: configuration.display, windowFrame: current) else {
            return .failed(ActionFailure(message: "The selected display is not available."))
        }

        let target = configuration.preset.targetFrame(in: usable, currentSize: current)

        guard setPosition(of: window, to: CGPoint(x: target.x, y: target.y)) else {
            return .failed(ActionFailure(message: "Could not move the \(label) window. It may not be movable."))
        }
        guard setSize(of: window, to: CGSize(width: target.width, height: target.height)) else {
            return .failed(ActionFailure(message: "Could not resize the \(label) window. It may not be resizable."))
        }

        guard let result = frame(of: window) else {
            return .failed(ActionFailure(message: "Could not verify the \(label) window position."))
        }

        let tolerance = 2.0
        let matches = abs(result.x - target.x) <= tolerance
            && abs(result.y - target.y) <= tolerance
            && abs(result.width - target.width) <= tolerance
            && abs(result.height - target.height) <= tolerance

        return matches
            ? .succeeded
            : .failed(ActionFailure(message: "The \(label) window did not reach the requested position."))
    }

    @MainActor
    private func waitForWindow(of axApplication: AXUIElement, timeout: TimeInterval = 8) async -> AXUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while !Task.isCancelled {
            if let window = targetWindow(of: axApplication) {
                return window
            }
            if Date() >= deadline {
                return nil
            }
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                return nil
            }
        }
        return nil
    }

    @MainActor
    private func targetWindow(of axApplication: AXUIElement) -> AXUIElement? {
        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement],
              !windows.isEmpty else {
            return nil
        }

        if windows.count == 1 {
            return windows[0]
        }

        if let main = windows.first(where: { boolAttribute($0, kAXMainAttribute) }) {
            return main
        }
        if let focused = windows.first(where: { boolAttribute($0, kAXFocusedAttribute) }) {
            return focused
        }
        return nil
    }

    private func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let boolValue = value as? Bool else {
            return false
        }
        return boolValue
    }

    private func frame(of window: AXUIElement) -> WindowFrame? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue, let sizeValue,
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(unsafeBitCast(positionValue, to: AXValue.self), .cgPoint, &point),
              AXValueGetValue(unsafeBitCast(sizeValue, to: AXValue.self), .cgSize, &size) else {
            return nil
        }
        return WindowFrame(x: point.x, y: point.y, width: size.width, height: size.height)
    }

    private func setPosition(of window: AXUIElement, to point: CGPoint) -> Bool {
        var isSettable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &isSettable) == .success,
              isSettable.boolValue else {
            return false
        }
        var mutablePoint = point
        guard let value = AXValueCreate(.cgPoint, &mutablePoint) else { return false }
        return AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value) == .success
    }

    private func setSize(of window: AXUIElement, to size: CGSize) -> Bool {
        var isSettable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &isSettable) == .success,
              isSettable.boolValue else {
            return false
        }
        var mutableSize = size
        guard let value = AXValueCreate(.cgSize, &mutableSize) else { return false }
        return AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value) == .success
    }

    @MainActor
    private func usableFrame(for selection: WindowDisplaySelection, windowFrame: WindowFrame) -> WindowFrame? {
        let screen: NSScreen?
        switch selection {
        case .main:
            screen = NSScreen.main
        case .current:
            screen = screenContaining(windowFrame)
        case .display(let identifier):
            screen = NSScreen.screens.first { screenIdentifier($0) == identifier }
            if screen == nil { return nil }
        }

        guard let screen else { return nil }
        return axFrame(of: screen.visibleFrame)
    }

    @MainActor
    private func screenContaining(_ frame: WindowFrame) -> NSScreen? {
        let center = CGPoint(x: frame.x + frame.width / 2, y: frame.y + frame.height / 2)
        for screen in NSScreen.screens {
            if axFrame(of: screen.frame).contains(center) {
                return screen
            }
        }
        return NSScreen.main
    }

    @MainActor
    private func axFrame(of cocoaFrame: NSRect) -> WindowFrame {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? cocoaFrame.height
        return WindowFrame(
            x: cocoaFrame.origin.x,
            y: primaryHeight - (cocoaFrame.origin.y + cocoaFrame.height),
            width: cocoaFrame.width,
            height: cocoaFrame.height
        )
    }

    @MainActor
    private func screenIdentifier(_ screen: NSScreen) -> String? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return number.stringValue
    }
}

private extension WindowFrame {
    func contains(_ point: CGPoint) -> Bool {
        point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height
    }
}
