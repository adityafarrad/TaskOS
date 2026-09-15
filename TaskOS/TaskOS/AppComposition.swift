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

enum PersistenceHealth: Sendable, Equatable {
    case onDisk
    case recovered(backup: URL?)
    case volatile(reason: String)
}

@MainActor
final class AppComposition {
    static let shared = AppComposition()

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
            || ProcessInfo.processInfo.environment["UI_TESTING"] == "1"
    }

    static var isTesting: Bool {
        isUITesting || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

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
    let admissionEvents: any AdmissionEventRepository
    let drafts: any DraftRepository
    let permissions: any PermissionStatusProvider
    let persistenceHealth: PersistenceHealth

    private let catalog: WorkspaceResourceCatalog
    private let applicationCatalog: ApplicationCatalogService
    private let sessionObserver: SystemSessionObserver
    private let lifecycleSource: ApplicationLifecycleSource
    private let wakeSource: WakeTriggerSource
    private let displaySource: DisplayTriggerSource
    private let volumeSource: VolumeTriggerSource
    private let powerSource: PowerBatteryTriggerSource
    private var systemChangeTokens: [NSObjectProtocol] = []

    init() {
        let clock = SystemClock()
        let catalog = WorkspaceResourceCatalog()
        self.applicationCatalog = ApplicationCatalogService(provider: catalog)

        let container: ModelContainer
        let persistenceHealth: PersistenceHealth
        if Self.isTesting {
            container = Self.makeContainer(inMemory: true)
            persistenceHealth = .onDisk
        } else {
            do {
                container = try ModelContainer(
                    for: WorkflowRecord.self,
                    RunRecordEntry.self,
                    AdmissionEventRecord.self,
                    DraftRecord.self
                )
                persistenceHealth = .onDisk
            } catch {
                let backup = Self.moveAsideDefaultStore()
                if let recovered = try? ModelContainer(
                    for: WorkflowRecord.self,
                    RunRecordEntry.self,
                    AdmissionEventRecord.self,
                    DraftRecord.self
                ) {
                    container = recovered
                    persistenceHealth = .recovered(backup: backup)
                } else {
                    container = Self.makeContainer(inMemory: true)
                    persistenceHealth = .volatile(reason: error.localizedDescription)
                }
            }
        }

        let runHistory = SwiftDataRunHistoryRepository(modelContainer: container)
        let admissionEvents = SwiftDataAdmissionEventRepository(modelContainer: container)
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
        self.admissionEvents = admissionEvents
        self.drafts = SwiftDataDraftRepository(modelContainer: container)
        let permissions = SystemPermissionStatusProvider()
        self.permissions = permissions
        self.preparer = CreationPreparer(
            catalog: catalog,
            permissions: permissions
        )
        self.persistenceHealth = persistenceHealth
        self.runner = runner
        let coordinator = RunCoordinator(clock: clock, eventSink: admissionEvents) { definition, id in
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
        calendar.timeZone = .autoupdatingCurrent
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

        let center = NotificationCenter.default
        let timeZoneToken = center.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.scheduleRegistry.refresh()
            }
        }
        let clockToken = center.addObserver(
            forName: .NSSystemClockDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.scheduleRegistry.refresh()
            }
        }
        self.systemChangeTokens = [timeZoneToken, clockToken]
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = inMemory ? ModelConfiguration(isStoredInMemoryOnly: true) : ModelConfiguration()
        do {
            return try ModelContainer(
                for: WorkflowRecord.self,
                RunRecordEntry.self,
                AdmissionEventRecord.self,
                DraftRecord.self,
                configurations: configuration
            )
        } catch {
            preconditionFailure("TaskOS could not create a data store: \(error.localizedDescription)")
        }
    }

    private static func moveAsideDefaultStore() -> URL? {
        let storeURL = ModelConfiguration().url
        let fileManager = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupBase = storeURL.deletingLastPathComponent().appendingPathComponent("TaskOS-store-backup-\(stamp).store")

        var moved = false
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: storeURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: backupBase.path + suffix)
            if (try? fileManager.moveItem(at: source, to: destination)) != nil {
                moved = true
            }
        }
        return moved ? backupBase : nil
    }

    func loadApplications() async -> [ApplicationResource] {
        await catalog.installedApplications()
    }

    func loadApplicationSnapshot() async -> ApplicationSnapshot {
        await applicationCatalog.refresh()
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
    static let taskOSRuntimeStateDidChange = Notification.Name("taskOSRuntimeStateDidChange")
}
