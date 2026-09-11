import AppKit
import Foundation
import TaskOSCore

@MainActor
final class DisplayTriggerSource: TriggerSource {
    private var token: NSObjectProtocol?
    private var handler: (@Sendable (ObservedTriggerEvent) -> Void)?
    private var reconciler = DeviceStateReconciler()
    private var externalByID: [String: Bool] = [:]

    nonisolated func start(_ handler: @escaping @Sendable (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID {
        await MainActor.run {
            self.handler = handler
            let map = Self.currentDisplays()
            self.reconciler.establishBaseline(Array(map.keys))
            self.externalByID = map

            self.token = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.screensChanged() }
            }
        }
        return TriggerRegistrationID()
    }

    nonisolated func stop(_ id: TriggerRegistrationID) async {
        await MainActor.run {
            if let token = self.token {
                NotificationCenter.default.removeObserver(token)
            }
            self.token = nil
            self.handler = nil
        }
    }

    private func screensChanged() {
        let map = Self.currentDisplays()
        let transition = reconciler.reconcile(Array(map.keys))
        for identifier in transition.added {
            handler?(.displayConnected(identifier: identifier, isExternal: map[identifier] ?? false))
        }
        for identifier in transition.removed {
            handler?(.displayDisconnected(identifier: identifier, isExternal: externalByID[identifier] ?? false))
        }
        externalByID = map
    }

    static func currentDisplays() -> [String: Bool] {
        var result: [String: Bool] = [:]
        for screen in NSScreen.screens {
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = CGDirectDisplayID(number.uint32Value)
            result[number.stringValue] = CGDisplayIsBuiltin(displayID) == 0
        }
        return result
    }
}
