import Foundation
import Observation
import TaskOSCore

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
    private(set) var applications: [ApplicationResource] = []
    private(set) var stage: Stage = .composing
    private(set) var approvedRevision: WorkflowRevision?
    private(set) var notice: String?
    private(set) var savedWorkflows: [SavedWorkflow] = []
    private(set) var libraryError: String?
    private(set) var history: [RunRecord] = []
    private(set) var draftName = "Untitled"
    var librarySearch = ""
    var renameTarget: AutomationID?
    var renameText = ""
    private(set) var notificationPermission: PermissionState = .notDetermined
    private(set) var accessibilityPermission: PermissionState = .notDetermined
    private(set) var launchAtLogin = LaunchAtLogin.isEnabled
    private(set) var settingsNotice: String?

    private let composition: AppComposition
    private var draftID = AutomationID()
    private var startingRevision = WorkflowRevision(1)
    private var editingWorkflowID: AutomationID?
    private var lastSavedSignature: String?
    private var lastSavedID: AutomationID?
    private var lastDefinition: AutomationDefinition?
    private var applicationsLoaded = false

    var currentRevision: WorkflowRevision {
        WorkflowRevision(startingRevision.value + document.revision.value - 1)
    }

    init(composition: AppComposition = .shared) {
        self.composition = composition
    }

    var text: String { document.text }
    var actions: [ComposerAction] { document.actions }
    var unresolvedTexts: [String] { document.unresolvedTexts }
    var canUndo: Bool { document.canUndo }
    var canRedo: Bool { document.canRedo }

    var hasUnresolved: Bool {
        document.hasUnresolvedText || document.hasUnresolvedActions
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

    func loadApplicationsIfNeeded() {
        guard !applicationsLoaded else { return }
        applicationsLoaded = true
        loadLibrary()
        loadHistory()
        refreshPermissions()
        Task { [weak self] in
            guard let self else { return }
            let loaded = await composition.loadApplications()
            self.applications = loaded
            self.refreshSuggestions()
            self.autoResolveApplications()
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
            let runID = UUID()
            try? await self.composition.runHistory.append(self.runningRecord(for: definition, id: runID))
            let record = await self.composition.runner.run(definition, id: runID)
            self.stage = .finished(record)
            await self.record(record)
        }
    }

    func requestAccessibilityPermission() {
        AccessibilityPermission.request()
        notice = "If TaskOS is listed in System Settings, turn it on, then run Preview again."
    }

    func loadLibrary() {
        Task { [weak self] in
            guard let self else { return }
            do {
                self.savedWorkflows = try await self.composition.repository.loadAll()
                self.libraryError = nil
            } catch {
                self.libraryError = "Could not load saved workflows: \(error.localizedDescription)"
            }
        }
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

        let workflow = SavedWorkflow(definition: definition, isEnabled: false)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.composition.repository.save(workflow)
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

    func refreshPermissions() {
        Task { [weak self] in
            guard let self else { return }
            self.notificationPermission = await self.composition.permissions.state(for: .notifications)
            self.accessibilityPermission = await self.composition.permissions.state(for: .accessibility)
            self.launchAtLogin = LaunchAtLogin.isEnabled
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
            self.loadLibrary()
            self.settingsNotice = "All saved workflows deleted."
        }
    }

    func newWorkflow() {
        draftID = AutomationID()
        editingWorkflowID = nil
        lastSavedSignature = nil
        lastSavedID = nil
        startingRevision = WorkflowRevision(1)
        draftName = "Untitled"
        document = ComposerDocument()
        suggestions = []
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
    }

    func loadForEditing(_ workflow: SavedWorkflow) {
        draftID = workflow.id
        draftName = workflow.name
        startingRevision = workflow.definition.revision
        editingWorkflowID = workflow.id
        lastSavedID = workflow.id
        document = ComposerDocument(text: CanonicalPhrase.command(for: workflow.definition.actions))
        autoResolveApplications()
        lastSavedSignature = currentSignature
        refreshSuggestions()
        resetPreview()
        notice = "Editing \"\(workflow.name)\" (revision \(workflow.definition.revision.value))."
    }

    func loadHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.composition.runHistory.markRunningAsInterrupted()
                self.history = try await self.composition.runHistory.recentRuns(limit: 50)
            } catch {
                self.libraryError = "Could not load run history: \(error.localizedDescription)"
            }
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
    }

    private func refreshSuggestions() {
        suggestions = composition.suggestions.suggestions(for: document.text, applications: applications)
    }

    private func autoResolveApplications() {
        for action in document.actions {
            let name: String?
            let resolved: ResourceReference?
            switch action.draft {
            case .openApplication(let value, let reference):
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
