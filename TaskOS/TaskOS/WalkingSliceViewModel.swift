import Foundation
import Observation
import TaskOSCore

@MainActor
@Observable
final class WalkingSliceViewModel {
    enum State: Equatable {
        case idle
        case running
        case finished(RunRecord)
    }

    private(set) var state: State = .idle
    private let composition: AppComposition
    private var runTask: Task<Void, Never>?

    init(composition: AppComposition = .shared) {
        self.composition = composition
    }

    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }

    func run() {
        guard !isRunning else { return }
        state = .running

        let definition = composition.walkingSliceDefinition()
        let runner = composition.runner

        runTask = Task { [weak self] in
            let record = await runner.run(definition)
            self?.state = .finished(record)
        }
    }
}
