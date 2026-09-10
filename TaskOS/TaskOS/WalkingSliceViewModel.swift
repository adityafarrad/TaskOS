import Foundation
import Observation
import TaskOSCore

@MainActor
@Observable
final class ReviewViewModel {
    enum Stage: Equatable {
        case idle
        case preparing
        case previewed(WorkflowPreview)
        case running
        case finished(RunRecord)
    }

    private(set) var stage: Stage = .idle
    private(set) var definition: AutomationDefinition
    private(set) var approvedRevision: WorkflowRevision?

    private let composition: AppComposition
    private var runTask: Task<Void, Never>?

    init(composition: AppComposition = .shared) {
        self.composition = composition
        self.definition = composition.initialDefinition()
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
        guard let preview, preview.revision == definition.revision, preview.isRunnable else {
            return false
        }
        return approvedRevision == definition.revision
    }

    func prepare() {
        guard !isBusy else { return }
        stage = .preparing

        let definition = self.definition
        let preparer = composition.preparer
        let approvals = composition.approvals

        Task { [weak self] in
            let preview = await preparer.prepare(definition)
            await approvals.approve(definition)
            self?.approvedRevision = definition.revision
            self?.stage = .previewed(preview)
        }
    }

    func test() {
        guard canTest, !isBusy else { return }
        stage = .running

        let definition = self.definition
        let runner = composition.runner

        runTask = Task { [weak self] in
            let record = await runner.run(definition)
            self?.stage = .finished(record)
        }
    }

    func setWaitDuration(_ duration: TimeInterval) {
        let updatedActions = definition.actions.map { action -> ActionConfiguration in
            if case .wait = action {
                return .wait(WaitAction(duration: duration))
            }
            return action
        }

        definition = AutomationDefinition(
            id: definition.id,
            name: definition.name,
            revision: definition.revision.next(),
            trigger: definition.trigger,
            actions: updatedActions
        )
        approvedRevision = nil
        stage = .idle

        let id = definition.id
        let approvals = composition.approvals
        Task {
            await approvals.revoke(id)
        }
    }
}
