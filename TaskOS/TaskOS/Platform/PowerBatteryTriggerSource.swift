import AppKit
import IOKit.ps
import TaskOSCore

@MainActor
final class PowerBatteryTriggerSource: TriggerSource {
    private var runLoopSource: CFRunLoopSource?
    private var handler: (@Sendable (ObservedTriggerEvent) -> Void)?
    private var lastOnExternal: Bool?
    private var lastPercentage: Int?

    nonisolated func start(_ handler: @escaping @Sendable (ObservedTriggerEvent) -> Void) async -> TriggerRegistrationID {
        await MainActor.run {
            self.handler = handler
            let state = Self.readState()
            self.lastOnExternal = state.onExternal
            self.lastPercentage = state.percentage
            handler(.batteryChanged(percentage: state.percentage))

            let context = Unmanaged.passUnretained(self).toOpaque()
            if let source = IOPSNotificationCreateRunLoopSource({ context in
                guard let context else { return }
                let source = Unmanaged<PowerBatteryTriggerSource>.fromOpaque(context).takeUnretainedValue()
                Task { @MainActor in source.readingsChanged() }
            }, context)?.takeRetainedValue() {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
                self.runLoopSource = source
            }
        }
        return TriggerRegistrationID()
    }

    nonisolated func stop(_ id: TriggerRegistrationID) async {
        await MainActor.run {
            if let source = self.runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            }
            self.runLoopSource = nil
            self.handler = nil
        }
    }

    private func readingsChanged() {
        let state = Self.readState()

        if lastOnExternal == nil {
            lastOnExternal = state.onExternal
        } else if state.onExternal != lastOnExternal {
            lastOnExternal = state.onExternal
            handler?(.powerSourceChanged(isOnExternalPower: state.onExternal))
        }

        lastPercentage = state.percentage
        handler?(.batteryChanged(percentage: state.percentage))
    }

    private static func readState() -> (onExternal: Bool, percentage: Int?) {
        var percentage: Int?

        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                      let type = description[kIOPSTypeKey] as? String,
                      type == kIOPSInternalBatteryType,
                      let current = description[kIOPSCurrentCapacityKey] as? Int,
                      let maximum = description[kIOPSMaxCapacityKey] as? Int,
                      maximum > 0 else {
                    continue
                }
                percentage = Int((Double(current) / Double(maximum)) * 100.0)
            }
        }

        var onExternal = false
        if let unmanagedType = IOPSGetProvidingPowerSourceType(nil) {
            onExternal = (unmanagedType.takeRetainedValue() as String) == (kIOPSACPowerValue as String)
        }

        return (onExternal, percentage)
    }
}
