import AppKit
import Foundation
import Observation
import TaskOSCore
import UniformTypeIdentifiers

@MainActor
@Observable
final class ComposerViewModel {
    enum Stage: Equatable {
        case composing
        case preparing
        case previewed(WorkflowPreview)
        case running
        case finished(RunRecord)
    }

    private(set) var document = ComposerDocument()
    private(set) var suggestions: [Suggestion] = []
    private(set) var highlightedSuggestion = 0
    private(set) var suggestionsDismissed = false
    private(set) var applications: [ApplicationResource] = []
    private(set) var displays: [DisplayResource] = []
    private(set) var hardware = HardwareAvailability(
        hasBattery: true,
        hasExternalDisplay: false,
        hasRemovableVolume: false
    )
    private(set) var stage: Stage = .composing
    private(set) var approvedRevision: WorkflowRevision?
    private(set) var notice: String?
    private(set) var savedWorkflows: [SavedWorkflow] = []
    private(set) var libraryError: String?
    private(set) var history: [RunRecord] = []
    private(set) var admissionEvents: [AdmissionEvent] = []
    private(set) var workflowAttention: [AutomationID: String] = [:]
    private(set) var automaticTriggersPaused = false
    private(set) var draftName = "Untitled"
    var librarySearch = ""
    var templateSearch = ""
    var discoverySearch = ""
    var showDiscovery = false
    var autoRunEnabled = false
    var scrollToTopToken = 0
    var renameTarget: AutomationID?
    var renameText = ""
    private(set) var notificationPermission: PermissionState = .notDetermined
    private(set) var accessibilityPermission: PermissionState = .notDetermined
    private(set) var launchAtLogin = LaunchAtLogin.isEnabled
    private(set) var settingsNotice: String?
    var showOnboarding = !OnboardingStore.hasCompleted

    private let composition: AppComposition
    private var draftID = AutomationID()
    private var startingRevision = WorkflowRevision(1)
    private var editingWorkflowID: AutomationID?
    private var lastSavedSignature: String?
    private var lastSavedID: AutomationID?
    private var lastDefinition: AutomationDefinition?
    private var applicationsLoaded = false
    private var autosaveTask: Task<Void, Never>?

    var currentRevision: WorkflowRevision {
        WorkflowRevision(startingRevision.value + document.revision.value - 1)
    }

    init(composition: AppComposition = .shared) {
        self.composition = composition
        NotificationCenter.default.addObserver(
            forName: .taskOSRunHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadHistory()
                self?.refreshRuntimeActivity()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .taskOSRuntimeStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshRuntimeActivity()
            }
        }
    }

    var text: String { document.text }
    var actions: [ComposerAction] { document.actions }
    var unresolvedTexts: [String] { document.unresolvedTexts }
    var canUndo: Bool { document.canUndo }
    var canRedo: Bool { document.canRedo }

    var hasUnresolved: Bool {
        document.hasUnresolvedText || document.hasUnresolvedActions || document.hasUnresolvedTrigger
    }

    var canPrepare: Bool {
        !document.actions.isEmpty && !hasUnresolved
    }

    var preview: WorkflowPreview? {
        if case .previewed(let preview) = stage {
            return preview
        }
        return nil
    }

    var isBusy: Bool {
        switch stage {
        case .preparing, .running:
            return true
        default:
            return false
        }
    }

    var canTest: Bool {
        guard let preview, preview.revision == currentRevision, preview.isRunnable else {
            return false
        }
        return approvedRevision == currentRevision
    }

    enum TriggerKind: Int, CaseIterable {
        case daily
        case weekdays
        case interval
        case once
    }

    static let intervalOptions: [TimeInterval] = [
        15 * 60, 30 * 60, 45 * 60, 60 * 60, 2 * 60 * 60,
        4 * 60 * 60, 8 * 60 * 60, 12 * 60 * 60, 24 * 60 * 60,
    ]

    enum TriggerFamily: Hashable {
        case manual
        case schedule
        case applicationLifecycle
        case wake
        case displayConnection
        case externalVolume
        case powerSource
        case batteryThreshold
    }

    var triggerFamily: TriggerFamily {
        switch document.trigger {
        case .manual:
            return .manual
        case .applicationLifecycle:
            return .applicationLifecycle
        case .wake:
            return .wake
        case .displayConnection:
            return .displayConnection
        case .externalVolume:
            return .externalVolume
        case .powerSource:
            return .powerSource
        case .batteryThreshold:
            return .batteryThreshold
        case .daily, .weekdays, .interval, .relative, .once, .oneTime:
            return .schedule
        }
    }

    var isScheduled: Bool { triggerFamily == .schedule }
    var isLifecycleTrigger: Bool { triggerFamily == .applicationLifecycle }
    var isWakeTrigger: Bool { triggerFamily == .wake }
    var isDisplayTrigger: Bool { triggerFamily == .displayConnection }
    var isVolumeTrigger: Bool { triggerFamily == .externalVolume }
    var isPowerTrigger: Bool { triggerFamily == .powerSource }
    var isBatteryTrigger: Bool { triggerFamily == .batteryThreshold }
    var supportsAutomaticRuns: Bool { triggerFamily != .manual }

    func setTriggerFamily(_ family: TriggerFamily) {
        switch family {
        case .manual:
            document.setTrigger(.manual)
            autoRunEnabled = false
        case .schedule:
            document.setTrigger(.daily(hour: 9, minute: 0))
        case .applicationLifecycle:
            document.setTrigger(.applicationLifecycle(application: nil, label: "", event: .launched))
        case .wake:
            document.setTrigger(.wake)
        case .displayConnection:
            document.setTrigger(.displayConnection(event: .connected, selection: .anyExternal))
        case .externalVolume:
            document.setTrigger(.externalVolume(event: .mounted, selection: .anyExternal))
        case .powerSource:
            document.setTrigger(.powerSource(.toBattery))
        case .batteryThreshold:
            document.setTrigger(.batteryThreshold(comparator: .below, percentage: 20))
        }
        afterEdit()
    }

    var powerEvent: PowerEvent {
        if case .powerSource(let event) = document.trigger {
            return event
        }
        return .toBattery
    }

    func setPowerEvent(_ event: PowerEvent) {
        document.setTrigger(.powerSource(event))
        afterEdit()
    }

    var batteryComparator: ThresholdComparison {
        if case .batteryThreshold(let comparator, _) = document.trigger {
            return comparator
        }
        return .below
    }

    var batteryPercentage: Int {
        if case .batteryThreshold(_, let percentage) = document.trigger {
            return percentage
        }
        return 20
    }

    func setBatteryComparator(_ comparator: ThresholdComparison) {
        document.setTrigger(.batteryThreshold(comparator: comparator, percentage: batteryPercentage))
        afterEdit()
    }

    func setBatteryPercentage(_ percentage: Int) {
        let clamped = min(max(percentage, BatteryThresholdTrigger.allowedRange.lowerBound),
                          BatteryThresholdTrigger.allowedRange.upperBound)
        document.setTrigger(.batteryThreshold(comparator: batteryComparator, percentage: clamped))
        afterEdit()
    }

    var displayEvent: DisplayEvent {
        if case .displayConnection(let event, _) = document.trigger {
            return event
        }
        return .connected
    }

    var displaySelection: DisplaySelection {
        if case .displayConnection(_, let selection) = document.trigger {
            return selection
        }
        return .anyExternal
    }

    func setDisplayEvent(_ event: DisplayEvent) {
        document.setTrigger(.displayConnection(event: event, selection: displaySelection))
        afterEdit()
    }

    func setDisplaySelection(_ selection: DisplaySelection) {
        document.setTrigger(.displayConnection(event: displayEvent, selection: selection))
        afterEdit()
    }

    var volumeEvent: VolumeEvent {
        if case .externalVolume(let event, _) = document.trigger {
            return event
        }
        return .mounted
    }

    var volumeSelection: VolumeSelection {
        if case .externalVolume(_, let selection) = document.trigger {
            return selection
        }
        return .anyExternal
    }

    func setVolumeEvent(_ event: VolumeEvent) {
        document.setTrigger(.externalVolume(event: event, selection: volumeSelection))
        afterEdit()
    }

    var lifecycleEvent: LifecycleEvent {
        if case .applicationLifecycle(_, _, let event) = document.trigger {
            return event
        }
        return .launched
    }

    var lifecycleApplication: ResourceReference? {
        if case .applicationLifecycle(let application, _, _) = document.trigger {
            return application
        }
        return nil
    }

    var lifecycleLabel: String {
        if case .applicationLifecycle(_, let label, _) = document.trigger {
            return label
        }
        return ""
    }

    func setLifecycleEvent(_ event: LifecycleEvent) {
        document.setTrigger(.applicationLifecycle(application: lifecycleApplication, label: lifecycleLabel, event: event))
        afterEdit()
    }

    func setLifecycleApplication(_ application: ApplicationResource) {
        document.setTrigger(
            .applicationLifecycle(
                application: .application(bundleIdentifier: application.bundleIdentifier, label: application.displayName),
                label: application.displayName,
                event: lifecycleEvent
            )
        )
        afterEdit()
    }

    var triggerKind: TriggerKind {
        switch document.trigger {
        case .weekdays:
            return .weekdays
        case .interval, .relative:
            return .interval
        case .once, .oneTime:
            return .once
        case .daily, .manual, .applicationLifecycle, .wake, .displayConnection,
             .externalVolume, .powerSource, .batteryThreshold:
            return .daily
        }
    }

    var upcomingOccurrences: [Date] {
        let now = composition.clock.now()
        guard let configuration = document.triggerConfiguration(relativeTo: now),
              case .schedule(let schedule) = configuration else {
            return []
        }
        return composition.scheduleCalculator.nextOccurrences(of: schedule, after: now, count: 3)
    }

    var timeDate: Date {
        let calendar = Calendar.current
        let base = composition.clock.now()
        switch document.trigger {
        case .daily(let hour, let minute), .weekdays(_, let hour, let minute), .once(let hour, let minute):
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        case .oneTime(let date):
            return date
        case .relative, .interval, .manual, .applicationLifecycle, .wake,
             .displayConnection, .externalVolume, .powerSource, .batteryThreshold:
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
        }
    }

    var scheduleWeekdays: Set<Weekday> {
        if case .weekdays(let days, _, _) = document.trigger {
            return days
        }
        return []
    }

    var scheduleIntervalSeconds: TimeInterval {
        switch document.trigger {
        case .interval(let seconds), .relative(let seconds):
            return seconds
        default:
            return 30 * 60
        }
    }

    var oneTimeDate: Date {
        switch document.trigger {
        case .oneTime(let date):
            return date
        case .once(let hour, let minute):
            let base = composition.clock.now()
            return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        default:
            return composition.clock.now().addingTimeInterval(3600)
        }
    }

    func addSchedule() {
        document.setTrigger(.daily(hour: 9, minute: 0))
        afterEdit()
    }

    func makeManual() {
        document.setTrigger(.manual)
        autoRunEnabled = false
        afterEdit()
    }

    func setTriggerKind(_ kind: TriggerKind) {
        switch kind {
        case .daily:
            document.setTrigger(.daily(hour: 9, minute: 0))
        case .weekdays:
            document.setTrigger(.weekdays(Weekday.weekdays, hour: 9, minute: 0))
        case .interval:
            document.setTrigger(.interval(30 * 60))
        case .once:
            document.setTrigger(.oneTime(composition.clock.now().addingTimeInterval(3600)))
        }
        afterEdit()
    }

    func setTimeDate(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0

        switch document.trigger {
        case .weekdays(let days, _, _):
            document.setTrigger(.weekdays(days, hour: hour, minute: minute))
        case .once:
            document.setTrigger(.once(hour: hour, minute: minute))
        case .oneTime(let existing):
            let merged = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: existing) ?? existing
            document.setTrigger(.oneTime(merged))
        default:
            document.setTrigger(.daily(hour: hour, minute: minute))
        }
        afterEdit()
    }

    func toggleWeekday(_ day: Weekday) {
        var days = scheduleWeekdays
        if days.contains(day) {
            days.remove(day)
        } else {
            days.insert(day)
        }
        if days.isEmpty {
            days = [day]
        }
        let (hour, minute) = triggerClock
        document.setTrigger(.weekdays(days, hour: hour, minute: minute))
        afterEdit()
    }

    func setScheduleInterval(_ seconds: TimeInterval) {
        document.setTrigger(.interval(seconds))
        afterEdit()
    }

    func setOneTimeDate(_ date: Date) {
        document.setTrigger(.oneTime(date))
        afterEdit()
    }

    private var triggerClock: (hour: Int, minute: Int) {
        switch document.trigger {
        case .daily(let hour, let minute), .weekdays(_, let hour, let minute), .once(let hour, let minute):
            return (hour, minute)
        case .oneTime(let date):
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (components.hour ?? 9, components.minute ?? 0)
        default:
            return (9, 0)
        }
    }

    func loadApplicationsIfNeeded() {
        guard !applicationsLoaded else { return }
        applicationsLoaded = true
        recoverInterruptedRuns()
        loadLibrary()
        loadHistory()
        refreshRuntimeActivity()
        refreshPermissions()
        Task { [weak self] in
            guard let self else { return }
            let loaded = await composition.loadApplications()
            self.applications = loaded
            self.displays = await composition.loadDisplays()
            self.hardware = composition.hardwareAvailability()
            self.refreshSuggestions()
            self.autoResolveApplications()
            self.restoreDraftIfNeeded()
        }
    }

    func setText(_ value: String) {
        guard value != document.text else { return }
        document.setText(value)
        afterEdit()
    }

    func accept(_ suggestion: Suggestion) {
        document.accept(suggestion)
        afterEdit()
    }

    func add(_ draft: ComposerActionDraft) {
        document.addAction(draft)
        afterEdit()
    }

    func remove(id: UUID) {
        document.removeAction(id: id)
        afterEdit()
    }

    func moveUp(id: UUID) {
        document.moveActionUp(id: id)
        afterEdit()
    }

    func moveDown(id: UUID) {
        document.moveActionDown(id: id)
        afterEdit()
    }

    func updateWait(id: UUID, duration: TimeInterval) {
        document.updateAction(id: id, draft: .wait(duration))
        afterEdit()
    }

    func updateOpenName(id: UUID, name: String) {
        document.updateAction(id: id, draft: .openApplication(name: name, resolved: nil))
        autoResolveApplications()
        afterEdit()
    }

    func updateWebsiteURL(id: UUID, url: String) {
        guard case .openWebsite(_, let browser) = actionDraft(id: id) else { return }
        document.updateAction(id: id, draft: .openWebsite(url: url, browser: browser))
        afterEdit()
    }

    func updateWebsiteBrowser(id: UUID, browser: ResourceReference?) {
        document.setWebsiteBrowser(id: id, browser: browser)
        afterEdit()
    }

    func updateArrangePreset(id: UUID, preset: WindowPreset) {
        guard case .arrangeWindow(let name, let resolved, _, let display) = actionDraft(id: id) else { return }
        document.updateAction(id: id, draft: .arrangeWindow(name: name, resolved: resolved, preset: preset, display: display))
        afterEdit()
    }

    func updateArrangeDisplay(id: UUID, display: WindowDisplaySelection) {
        guard case .arrangeWindow(let name, let resolved, let preset, _) = actionDraft(id: id) else { return }
        document.updateAction(id: id, draft: .arrangeWindow(name: name, resolved: resolved, preset: preset, display: display))
        afterEdit()
    }

    private func actionDraft(id: UUID) -> ComposerActionDraft? {
        document.actions.first { $0.id == id }?.draft
    }

    func resolve(id: UUID, application: ApplicationResource) {
        document.resolveApplication(
            id: id,
            reference: .application(bundleIdentifier: application.bundleIdentifier, label: application.displayName)
        )
        afterEdit()
    }

    func updateNotification(id: UUID, title: String, message: String) {
        document.updateAction(id: id, draft: .showNotification(title: title, message: message))
        afterEdit()
    }

    func updateCopyText(id: UUID, text: String) {
        document.updateAction(id: id, draft: .copyText(text))
        afterEdit()
    }

    func isMissingFile(_ target: FileTarget) -> Bool {
        !FileTargetResolver.exists(target)
    }

    func exportWorkflow(_ workflow: SavedWorkflow) {
        let alert = NSAlert()
        alert.messageText = "Export \"\(workflow.name)\"?"
        alert.informativeText = "The file may contain private information such as configured URLs, notification messages, and copied text. It does not include the enabled state, run history, permissions, or file access."
        alert.addButton(withTitle: "Export")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(workflow.name).taskos.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try WorkflowPortability.export(workflow.definition)
            try data.write(to: url)
            notice = "Exported \"\(workflow.name)\"."
        } catch {
            notice = "Could not export: \(error.localizedDescription)"
        }
    }

    func importWorkflow() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let definition = try WorkflowPortability.importWorkflow(data)
            let imported = SavedWorkflow(definition: definition, isEnabled: false)

            Task { [weak self] in
                guard let self else { return }
                try? await self.composition.repository.save(imported)
                self.loadLibrary()
                self.loadForEditing(imported)
                self.autoRunEnabled = false
                self.notice = "Imported \"\(imported.name)\". Choose the exact local resources, then save. It will not run automatically."
            }
        } catch {
            notice = "Could not import this workflow: \(error.localizedDescription)"
        }
    }

    func chooseFile(id: UUID) {
        guard let draft = actionDraft(id: id) else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let target = FileTarget(
            kind: isDirectory ? .folder : .file,
            displayName: FileManager.default.displayName(atPath: url.path),
            path: url.path,
            bookmark: try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        )

        switch draft {
        case .revealInFinder:
            document.updateAction(id: id, draft: .revealInFinder(target: target))
        default:
            document.updateAction(id: id, draft: .openFile(target: target))
        }
        afterEdit()
    }

    func undo() {
        document.undo()
        afterEdit()
    }

    func redo() {
        document.redo()
        afterEdit()
    }

    func prepare() {
        notice = nil
        guard let definition = document.makeDefinition(name: draftName, id: draftID, revision: currentRevision) else {
            notice = "Finish resolving every step before previewing."
            return
        }

        lastDefinition = definition
        stage = .preparing

        Task { [weak self] in
            guard let self else { return }
            let preview = await composition.preparer.prepare(definition)
            await composition.approvals.approve(definition)
            self.approvedRevision = definition.revision
            self.stage = .previewed(preview)
        }
    }

    func test() {
        guard canTest, let definition = lastDefinition else { return }
        stage = .running

        Task { [weak self] in
            guard let self else { return }
            guard await self.coordinatorIsIdle() else { return }
            let runID = UUID()
            try? await self.composition.runHistory.append(self.runningRecord(for: definition, id: runID))
            let record = await self.composition.runner.run(definition, id: runID)
            self.stage = .finished(record)
            await self.record(record)
        }
    }

    private func coordinatorIsIdle() async -> Bool {
        let status = await composition.coordinator.status()
        guard !status.isRunning, status.queuedCount == 0 else {
            stage = .composing
            notice = "A run is already in progress. Try again when it finishes."
            return false
        }
        return true
    }

    func requestAccessibilityPermission() {
        AccessibilityPermission.request()
        notice = "If TaskOS is listed in System Settings, turn it on, then run Preview again."
    }

    func loadLibrary() {
        NotificationCenter.default.post(name: .taskOSWorkflowLibraryDidChange, object: nil)
        Task { [weak self] in
            guard let self else { return }
            do {
                let workflows = try await self.composition.repository.loadAll()
                self.savedWorkflows = workflows
                self.libraryError = nil
                self.workflowAttention = await self.computeAttention(for: workflows)
            } catch {
                self.libraryError = "Could not load saved workflows: \(error.localizedDescription)"
            }
        }
    }

    private func computeAttention(for workflows: [SavedWorkflow]) async -> [AutomationID: String] {
        var attention: [AutomationID: String] = [:]
        for workflow in workflows {
            let preview = await composition.preparer.prepare(workflow.definition)
            guard !preview.isRunnable else { continue }
            let reason = preview.issues.first { $0.severity == .error }?.message
                ?? preview.actions.first { $0.status == .missingResource }?.detail
                ?? "Needs attention."
            attention[workflow.id] = reason
        }
        return attention
    }

    func save() {
        notice = nil
        let signature = currentSignature
        let isUpdatingExisting = editingWorkflowID != nil
            || (lastSavedSignature != nil && lastSavedSignature == signature)

        let targetID: AutomationID
        if let editingWorkflowID {
            targetID = editingWorkflowID
        } else if lastSavedSignature == signature, let lastSavedID {
            targetID = lastSavedID
        } else {
            targetID = AutomationID()
        }

        let revision = isUpdatingExisting ? currentRevision : WorkflowRevision(1)

        guard let definition = document.makeDefinition(name: draftName, id: targetID, revision: revision) else {
            notice = "Finish resolving every step before saving."
            return
        }

        let isAutomatic = autoRunEnabled && supportsAutomaticRuns
        let workflow = SavedWorkflow(definition: definition, isEnabled: isAutomatic)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.composition.repository.save(workflow)
                if definition.trigger.schedule != nil {
                    if isAutomatic {
                        await self.composition.scheduleRegistry.register(definition)
                    } else {
                        await self.composition.scheduleRegistry.unregister(definition.id)
                    }
                }
                if definition.trigger.isEventTrigger {
                    if isAutomatic {
                        await self.composition.eventTriggerRegistry.register(definition)
                    } else {
                        await self.composition.eventTriggerRegistry.unregister(definition.id)
                    }
                }
                self.autosaveTask?.cancel()
                try? await self.composition.drafts.clearDraft()
                self.editingWorkflowID = nil
                self.lastSavedSignature = signature
                self.lastSavedID = targetID
                self.startingRevision = revision
                self.notice = isUpdatingExisting
                    ? "Updated \"\(self.draftName)\"."
                    : "Saved \"\(self.draftName)\"."
                self.loadLibrary()
            } catch {
                self.notice = "Could not save: \(error.localizedDescription)"
            }
        }
    }

    func completeOnboarding() {
        OnboardingStore.complete()
        showOnboarding = false
    }

    func showOnboardingHelp() {
        showOnboarding = true
    }

    func refreshPermissions() {
        Task { [weak self] in
            guard let self else { return }
            self.notificationPermission = await self.composition.permissions.state(for: .notifications)
            self.accessibilityPermission = await self.composition.permissions.state(for: .accessibility)
            self.launchAtLogin = LaunchAtLogin.isEnabled
        }
    }

    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if LaunchAtLogin.setEnabled(enabled) {
            launchAtLogin = LaunchAtLogin.isEnabled
            settingsNotice = enabled ? "Launch at login enabled." : "Launch at login disabled."
        } else {
            launchAtLogin = LaunchAtLogin.isEnabled
            settingsNotice = "Could not change launch at login. Allow it in System Settings > General > Login Items."
        }
    }

    func clearHistory() {
        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.runHistory.clear()
            self.history = []
            self.settingsNotice = "Run history cleared."
        }
    }

    func clearAllWorkflows() {
        Task { [weak self] in
            guard let self else { return }
            for workflow in self.savedWorkflows {
                try? await self.composition.repository.delete(id: workflow.id)
            }
            await self.composition.scheduleRegistry.replaceAll([])
            await self.composition.eventTriggerRegistry.replaceAll([])
            self.loadLibrary()
            self.settingsNotice = "All saved workflows deleted."
        }
    }

    var capabilityGuides: [CapabilityGuide] {
        CapabilityGuideCatalog.standard
    }

    var filteredGuides: [CapabilityGuide] {
        let query = discoverySearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return capabilityGuides }
        return capabilityGuides.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.whatItDoes.localizedCaseInsensitiveContains(query)
                || $0.example.localizedCaseInsensitiveContains(query)
        }
    }

    func guideIsAvailable(_ guide: CapabilityGuide) -> Bool {
        switch guide.id {
        case "trigger.batteryThreshold":
            return hardware.hasBattery
        case "trigger.displayConnection":
            return hardware.hasExternalDisplay
        case "trigger.externalVolume":
            return hardware.hasRemovableVolume
        default:
            return true
        }
    }

    var templates: [AutomationTemplate] {
        composition.templates.templates
    }

    var filteredTemplates: [AutomationTemplate] {
        let query = templateSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return templates }
        return templates.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    func loadTemplate(_ template: AutomationTemplate) {
        draftID = AutomationID()
        editingWorkflowID = nil
        lastSavedSignature = nil
        lastSavedID = nil
        startingRevision = WorkflowRevision(1)
        draftName = template.name
        autoRunEnabled = false
        document = template.document()
        autoResolveApplications()
        refreshSuggestions()
        resetPreview()
        notice = "Loaded template \"\(template.name)\". Fill in the highlighted items, then Preview."
    }

    func newWorkflow() {
        draftID = AutomationID()
        editingWorkflowID = nil
        lastSavedSignature = nil
        lastSavedID = nil
        startingRevision = WorkflowRevision(1)
        draftName = "Untitled"
        autoRunEnabled = false
        document = ComposerDocument()
        suggestions = []
        autosaveTask?.cancel()
        Task { [weak self] in
            try? await self?.composition.drafts.clearDraft()
        }
        resetPreview()
        notice = "Started a new workflow."
    }

    private var currentSignature: String {
        let actions = document.resolvedActions() ?? []
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payload = (try? encoder.encode(actions)).map { String(decoding: $0, as: UTF8.self) } ?? document.text
        return "\(draftName)|\(payload)"
    }

    func runSaved(_ workflow: SavedWorkflow) {
        stage = .running
        Task { [weak self] in
            guard let self else { return }
            guard await self.coordinatorIsIdle() else { return }
            let runID = UUID()
            try? await self.composition.runHistory.append(self.runningRecord(for: workflow.definition, id: runID))
            let record = await self.composition.runner.run(workflow.definition, id: runID)
            self.stage = .finished(record)
            await self.record(record)
        }
    }

    func updateName(_ value: String) {
        draftName = value
        resetPreview()
        scheduleDraftAutosave()
    }

    func loadForEditing(_ workflow: SavedWorkflow) {
        draftID = workflow.id
        draftName = workflow.name
        startingRevision = workflow.definition.revision
        editingWorkflowID = workflow.id
        lastSavedID = workflow.id
        document = ComposerDocument(text: CanonicalPhrase.command(for: workflow.definition.actions))
        applyTrigger(workflow.definition.trigger)
        autoRunEnabled = workflow.isEnabled
        autoResolveApplications()
        lastSavedSignature = currentSignature
        refreshSuggestions()
        resetPreview()
        if let reason = workflowAttention[workflow.id] {
            notice = "Editing \"\(workflow.name)\". Needs attention: \(reason)"
        } else {
            notice = "Editing \"\(workflow.name)\" (revision \(workflow.definition.revision.value))."
        }
        scrollToTopToken += 1
    }

    private func recoverInterruptedRuns() {
        Task { [composition] in
            try? await composition.runHistory.markRunningAsInterrupted()
        }
    }

    func loadHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.history = try await self.composition.runHistory.recentRuns(limit: 50)
            } catch {
                self.libraryError = "Could not load run history: \(error.localizedDescription)"
            }
        }
    }

    func refreshAll() {
        loadLibrary()
        loadHistory()
        refreshRuntimeActivity()
        refreshPermissions()
        Task { [weak self] in
            guard let self else { return }
            self.displays = await self.composition.loadDisplays()
            self.hardware = self.composition.hardwareAvailability()
        }
    }

    func refreshRuntimeActivity() {
        Task { [weak self] in
            guard let self else { return }
            let status = await self.composition.coordinator.status()
            self.admissionEvents = status.recentEvents
            self.automaticTriggersPaused = status.isPaused
        }
    }

    private func runningRecord(for definition: AutomationDefinition, id: UUID) -> RunRecord {
        RunRecord.starting(definition, id: id)
    }

    private func record(_ run: RunRecord) async {
        do {
            try await composition.runHistory.update(run)
            history = try await composition.runHistory.recentRuns(limit: 50)
        } catch {
            libraryError = "Could not save run history: \(error.localizedDescription)"
        }
    }

    func deleteSaved(_ workflow: SavedWorkflow) {
        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.repository.delete(id: workflow.id)
            await self.composition.scheduleRegistry.unregister(workflow.id)
            await self.composition.eventTriggerRegistry.unregister(workflow.id)
            self.loadLibrary()
        }
    }

    func setEnabled(_ workflow: SavedWorkflow, enabled: Bool) {
        guard workflow.definition.trigger.schedule != nil else { return }
        var updated = workflow
        updated.isEnabled = enabled
        updated.updatedAt = Date()

        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.repository.save(updated)
            if updated.isEnabled {
                await self.composition.scheduleRegistry.register(updated.definition)
            } else {
                await self.composition.scheduleRegistry.unregister(updated.id)
            }
            self.loadLibrary()
        }
    }

    var filteredWorkflows: [SavedWorkflow] {
        let query = librarySearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return savedWorkflows }
        return savedWorkflows.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func beginRename(_ workflow: SavedWorkflow) {
        renameTarget = workflow.id
        renameText = workflow.name
    }

    func cancelRename() {
        renameTarget = nil
        renameText = ""
    }

    func commitRename() {
        guard let id = renameTarget,
              let workflow = savedWorkflows.first(where: { $0.id == id }) else {
            cancelRename()
            return
        }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        cancelRename()
        guard !trimmed.isEmpty, trimmed != workflow.name else { return }

        let renamed = AutomationDefinition(
            id: workflow.definition.id,
            name: trimmed,
            revision: workflow.definition.revision.next(),
            trigger: workflow.definition.trigger,
            actions: workflow.definition.actions
        )
        let updated = SavedWorkflow(definition: renamed, isEnabled: workflow.isEnabled, updatedAt: Date())

        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.repository.save(updated)
            self.loadLibrary()
        }
    }

    func duplicate(_ workflow: SavedWorkflow) {
        let copyDefinition = AutomationDefinition(
            id: AutomationID(),
            name: "\(workflow.name) Copy",
            revision: WorkflowRevision(1),
            trigger: workflow.definition.trigger,
            actions: workflow.definition.actions
        )
        let copy = SavedWorkflow(definition: copyDefinition, isEnabled: false, updatedAt: Date())

        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.repository.save(copy)
            self.notice = "Duplicated \"\(workflow.name)\"."
            self.loadLibrary()
        }
    }

    private func afterEdit() {
        autoResolveApplications()
        refreshSuggestions()
        resetPreview()
        scheduleDraftAutosave()
    }

    private var currentID: AutomationID {
        editingWorkflowID ?? draftID
    }

    private func scheduleDraftAutosave() {
        let draft = ComposerDraft(id: currentID, name: draftName, text: document.text)
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            try? await self?.composition.drafts.saveDraft(draft)
        }
    }

    private func restoreDraftIfNeeded() {
        guard document.text.isEmpty, document.actions.isEmpty else { return }
        Task { [weak self] in
            guard let self else { return }
            guard let draft = try? await self.composition.drafts.loadDraft(),
                  !draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            self.draftID = draft.id
            self.draftName = draft.name
            self.document = ComposerDocument(text: draft.text)
            self.autoResolveApplications()
            self.refreshSuggestions()
            self.resetPreview()
            self.notice = "Recovered your unsaved draft."
        }
    }

    private func refreshSuggestions() {
        suggestions = composition.suggestions.suggestions(for: document.text, applications: applications)
        highlightedSuggestion = 0
        suggestionsDismissed = false
    }

    var visibleSuggestions: [Suggestion] {
        suggestionsDismissed ? [] : suggestions
    }

    func moveHighlight(by delta: Int) {
        guard !suggestions.isEmpty else { return }
        suggestionsDismissed = false
        let count = suggestions.count
        highlightedSuggestion = ((highlightedSuggestion + delta) % count + count) % count
    }

    func acceptHighlighted() {
        guard !suggestionsDismissed, suggestions.indices.contains(highlightedSuggestion) else { return }
        accept(suggestions[highlightedSuggestion])
    }

    func dismissSuggestions() {
        suggestionsDismissed = true
    }

    private func applyTrigger(_ trigger: TriggerConfiguration) {
        let draft: ComposerTriggerDraft
        switch trigger {
        case .manual:
            draft = .manual
        case .schedule(let schedule):
            switch schedule {
            case .daily(let hour, let minute):
                draft = .daily(hour: hour, minute: minute)
            case .weekdays(let days, let hour, let minute):
                draft = .weekdays(days, hour: hour, minute: minute)
            case .interval(let every, _):
                draft = .interval(every)
            case .oneTime(let date):
                draft = .oneTime(date)
            }
        case .applicationLifecycle(let trigger):
            draft = .applicationLifecycle(
                application: trigger.application.identifier.isEmpty ? nil : trigger.application,
                label: trigger.application.label,
                event: trigger.event
            )
        case .wake:
            draft = .wake
        case .displayConnection(let trigger):
            draft = .displayConnection(event: trigger.event, selection: trigger.selection)
        case .externalVolume(let trigger):
            draft = .externalVolume(event: trigger.event, selection: trigger.selection)
        case .powerSource(let trigger):
            draft = .powerSource(trigger.event)
        case .batteryThreshold(let trigger):
            draft = .batteryThreshold(comparator: trigger.comparator, percentage: trigger.percentage)
        }
        if draft != .manual {
            document.setTrigger(draft)
        }
    }

    private func autoResolveApplications() {
        if case .applicationLifecycle(let application, let label, let event) = document.trigger,
           application == nil,
           !label.isEmpty,
           let match = applications.first(where: { $0.displayName.caseInsensitiveCompare(label) == .orderedSame }) {
            document.setTrigger(
                .applicationLifecycle(
                    application: .application(bundleIdentifier: match.bundleIdentifier, label: match.displayName),
                    label: match.displayName,
                    event: event
                )
            )
        }

        for action in document.actions {
            let name: String?
            let resolved: ResourceReference?
            switch action.draft {
            case .openApplication(let value, let reference):
                name = value
                resolved = reference
            case .hideApplication(let value, let reference):
                name = value
                resolved = reference
            case .quitApplication(let value, let reference):
                name = value
                resolved = reference
            case .arrangeWindow(let value, let reference, _, _):
                name = value
                resolved = reference
            default:
                name = nil
                resolved = nil
            }

            guard let name, resolved == nil else { continue }
            if let match = applications.first(where: { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }) {
                document.resolveApplication(
                    id: action.id,
                    reference: .application(bundleIdentifier: match.bundleIdentifier, label: match.displayName)
                )
            }
        }
    }

    private func resetPreview() {
        switch stage {
        case .preparing, .previewed, .running, .finished:
            stage = .composing
            approvedRevision = nil
            let id = draftID
            let approvals = composition.approvals
            Task {
                await approvals.revoke(id)
            }
        case .composing:
            break
        }
    }
}
