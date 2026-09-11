import AppKit
import Foundation
import TaskOSCore

@MainActor
final class VolumeTriggerSource: TriggerSource {
    private var tokens: [NSObjectProtocol] = []
    private var handler: (@Sendable (ObservedTriggerEvent) -> Void)?
    private var reconciler = DeviceStateReconciler()
    private var externalByID: [String: Bool] = [:]

    nonisolated func start(_ handler: @escaping @Sendable (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID {
        await MainActor.run {
            self.handler = handler
            let map = Self.currentVolumes()
            self.reconciler.establishBaseline(Array(map.keys))
            self.externalByID = map

            let center = NSWorkspace.shared.notificationCenter
            let mount = center.addObserver(
                forName: NSWorkspace.didMountNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.volumesChanged() }
            }
            let unmount = center.addObserver(
                forName: NSWorkspace.didUnmountNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.volumesChanged() }
            }
            self.tokens = [mount, unmount]
        }
        return TriggerRegistrationID()
    }

    nonisolated func stop(_ id: TriggerRegistrationID) async {
        await MainActor.run {
            let center = NSWorkspace.shared.notificationCenter
            for token in self.tokens {
                center.removeObserver(token)
            }
            self.tokens = []
            self.handler = nil
        }
    }

    private func volumesChanged() {
        let map = Self.currentVolumes()
        let transition = reconciler.reconcile(Array(map.keys))
        for identifier in transition.added {
            handler?(.volumeMounted(identifier: identifier, isExternal: map[identifier] ?? false))
        }
        for identifier in transition.removed {
            handler?(.volumeUnmounted(identifier: identifier, isExternal: externalByID[identifier] ?? false))
        }
        externalByID = map
    }

    static func currentVolumes() -> [String: Bool] {
        let keys: [URLResourceKey] = [.volumeUUIDStringKey, .volumeIsInternalKey]
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys) else {
            return [:]
        }
        var result: [String: Bool] = [:]
        for url in urls {
            let values = try? url.resourceValues(forKeys: Set(keys))
            let identifier = values?.volumeUUIDString ?? url.path
            let isInternal = values?.volumeIsInternal ?? true
            result[identifier] = !isInternal
        }
        return result
    }
}
