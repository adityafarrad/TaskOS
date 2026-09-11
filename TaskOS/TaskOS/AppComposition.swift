import AppKit
import Foundation
import IOKit.ps
import SwiftData
import TaskOSCore

struct HardwareAvailability: Sendable, Equatable {
    var hasBattery: Bool
    var hasExternalDisplay: Bool
    var hasRemovableVolume: Bool
}

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    let clock: any CoreClock
    let runner: WorkflowRunner
    let coordinator: RunCoordinator
    let scheduleCalculator: ScheduleCalculator
    let scheduleRegistry: ScheduleRegistry
    let lifecycleSuppressor: LifecycleSuppressor
    let eventTriggerRegistry: EventTriggerRegistry
    let preparer: CreationPreparer
    let approvals: ApprovalRegistry
    let suggestions: SuggestionEngine
    let templates = TemplateCatalog.standard
    let repository: any AutomationRepository
    let runHistory: any RunHistoryRepository
    let drafts: any DraftRepository
    let permissions: any PermissionStatusProvider

    private let catalog: WorkspaceResourceCatalog
    private let sessionObserver: SystemSessionObserver
    private let lifecycleSource: ApplicationLifecycleSource
    private let wakeSource: WakeTriggerSource
    private let displaySource: DisplayTriggerSource
    private let volumeSource: VolumeTriggerSource
    private let powerSource: PowerBatteryTriggerSource

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()

        let container: ModelContainer
        do {
            container = try ModelContainer(for: WorkflowRecord.self, RunRecordEntry.self, DraftRecord.self)
        } catch {
            container = try! ModelContainer(
                for: WorkflowRecord.self,
                RunRecordEntry.self,
                DraftRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let runHistory = SwiftDataRunHistoryRepository(modelContainer: container)
        let lifecycleSuppressor = LifecycleSuppressor(clock: clock)
        let runner = WorkflowRunner(
            clock: clock,
            executors: [
                OpenApplicationExecutor(suppressor: lifecycleSuppressor),
                HideApplicationExecutor(),
                QuitApplicationExecutor(suppressor: lifecycleSuppressor),
                OpenFileExecutor(),
                RevealInFinderExecutor(),
                OpenWebsiteExecutor(),
                ArrangeWindowExecutor(),
                NotificationExecutor(),
                CopyTextExecutor(),
            ]
        )

        self.clock = clock
        self.catalog = catalog
        self.approvals = ApprovalRegistry()
        self.suggestions = SuggestionEngine()
        self.repository = SwiftDataAutomationRepository(modelContainer: container)
        self.runHistory = runHistory
        self.drafts = SwiftDataDraftRepository(modelContainer: container)
        let permissions = SystemPermissionStatusProvider()
        self.permissions = permissions
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: permissions
        )
        self.runner = runner
        let coordinator = RunCoordinator(clock: clock) { definition, id in
            try? await runHistory.append(RunRecord.starting(definition, id: id))
            await MainActor.run {
                NotificationCenter.default.post(name: .taskOSRunHistoryDidChange, object: nil)
            }
            let record = await runner.run(definition, id: id)
            try? await runHistory.update(record)
            await MainActor.run {
                NotificationCenter.default.post(name: .taskOSRunHistoryDidChange, object: nil)
            }
            return record
        }
        self.coordinator = coordinator

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let scheduleCalculator = ScheduleCalculator(calendar: calendar)
        self.scheduleCalculator = scheduleCalculator
        self.scheduleRegistry = ScheduleRegistry(
            clock: clock,
            calculator: scheduleCalculator,
            coordinator: coordinator
        )
        self.lifecycleSuppressor = lifecycleSuppressor
        self.eventTriggerRegistry = EventTriggerRegistry(
            clock: clock,
            coordinator: coordinator,
            suppressor: lifecycleSuppressor
        )
        self.lifecycleSource = ApplicationLifecycleSource()
        self.wakeSource = WakeTriggerSource()
        self.displaySource = DisplayTriggerSource()
        self.volumeSource = VolumeTriggerSource()
        self.powerSource = PowerBatteryTriggerSource()

        self.sessionObserver = SystemSessionObserver(coordinator: coordinator)
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }

    func loadDisplays() async -> [DisplayResource] {
        await catalog.installedDisplays()
    }

    func hardwareAvailability() -> HardwareAvailability {
        HardwareAvailability(
            hasBattery: Self.hasInternalBattery(),
            hasExternalDisplay: NSScreen.screens.contains { screen in
                guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                    return false
                }
                return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) == 0
            },
            hasRemovableVolume: Self.hasRemovableVolume()
        )
    }

    private static func hasInternalBattery() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               let type = description[kIOPSTypeKey] as? String,
               type == kIOPSInternalBatteryType {
                return true
            }
        }
        return false
    }

    private static func hasRemovableVolume() -> Bool {
        let keys: [URLResourceKey] = [.volumeIsInternalKey]
        guard let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys) else {
            return false
        }
        return urls.contains { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return values?.volumeIsInternal == false
        }
    }

    func syncTriggerRegistrations() async {
        let workflows = (try? await repository.loadAll()) ?? []
        let enabled = workflows
            .filter { $0.isEnabled }
            .map(\.definition)
        await scheduleRegistry.replaceAll(enabled)
        await eventTriggerRegistry.replaceAll(enabled)
    }

    func startEventTriggers() async {
        _ = await lifecycleSource.start { [eventTriggerRegistry] event in
            Task { await eventTriggerRegistry.handle(event) }
        }
        _ = await wakeSource.start { [eventTriggerRegistry] event in
            Task { await eventTriggerRegistry.handle(event) }
        }
        _ = await displaySource.start { [eventTriggerRegistry] event in
            Task { await eventTriggerRegistry.handle(event) }
        }
        _ = await volumeSource.start { [eventTriggerRegistry] event in
            Task { await eventTriggerRegistry.handle(event) }
        }
        _ = await powerSource.start { [eventTriggerRegistry] event in
            Task { await eventTriggerRegistry.handle(event) }
        }
    }
}

extension Notification.Name {
    static let taskOSRunHistoryDidChange = Notification.Name("taskOSRunHistoryDidChange")
    static let taskOSWorkflowLibraryDidChange = Notification.Name("taskOSWorkflowLibraryDidChange")
}
