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

    private let composition: AppComposition
    private let draftID = AutomationID()
    private var lastDefinition: AutomationDefinition?
    private var applicationsLoaded = false

    init(composition: AppComposition = .shared) {
        self.composition = composition
    }

    var text: String { document.text }
    var actions: [ComposerAction] { document.actions }
    var unresolvedTexts: [String] { document.unresolvedTexts }
    var canUndo: Bool { document.canUndo }
    var canRedo: Bool { document.canRedo }

    var hasUnresolved: Bool {
        document.hasUnresolvedText || document.hasUnresolvedApplications
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
        guard let preview, preview.revision == document.revision, preview.isRunnable else {
            return false
        }
        return approvedRevision == document.revision
    }

    func loadApplicationsIfNeeded() {
        guard !applicationsLoaded else { return }
        applicationsLoaded = true
        loadLibrary()
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
        guard let definition = document.makeDefinition(name: "Untitled", id: draftID, revision: document.revision) else {
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
            let record = await composition.runner.run(definition)
            self.stage = .finished(record)
        }
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
        guard let definition = document.makeDefinition(name: "Untitled", id: draftID, revision: document.revision) else {
            notice = "Finish resolving every step before saving."
            return
        }

        let workflow = SavedWorkflow(definition: definition, isEnabled: false)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.composition.repository.save(workflow)
                self.notice = "Saved."
                self.loadLibrary()
            } catch {
                self.notice = "Could not save: \(error.localizedDescription)"
            }
        }
    }

    func runSaved(_ workflow: SavedWorkflow) {
        stage = .running
        Task { [weak self] in
            guard let self else { return }
            let record = await self.composition.runner.run(workflow.definition)
            self.stage = .finished(record)
        }
    }

    func deleteSaved(_ workflow: SavedWorkflow) {
        Task { [weak self] in
            guard let self else { return }
            try? await self.composition.repository.delete(id: workflow.id)
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
            guard case .openApplication(let name, let resolved) = action.draft, resolved == nil else {
                continue
            }
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
