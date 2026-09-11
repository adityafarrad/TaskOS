import Foundation

public enum RunRequestSource: Sendable, Equatable, Hashable {
    case manual
    case automatic(TriggerID)

    public var isAutomatic: Bool {
        if case .automatic = self { return true }
        return false
    }
}

public enum AdmissionOutcome: Sendable, Equatable {
    case started
    case queued
    case suppressedDuplicate
    case suppressedCooldown
    case suppressedPaused
    case suppressedSessionNotReady
    case queueFull
    case rejected(String)
}

public enum AdmissionEventKind: String, Sendable, Codable, Equatable {
    case duplicateSuppressed
    case cooldownSuppressed
    case queueOverflow
    case expired
    case pausedCleared
    case sleepInterrupted

    public var displayName: String {
        switch self {
        case .duplicateSuppressed: return "Duplicate suppressed"
        case .cooldownSuppressed: return "Cooldown suppressed"
        case .queueOverflow: return "Queue was full"
        case .expired: return "Expired before running"
        case .pausedCleared: return "Cleared while paused"
        case .sleepInterrupted: return "Interrupted by sleep"
        }
    }
}

public struct AdmissionEvent: Sendable, Equatable, Hashable {
    public let automationID: AutomationID
    public let automationName: String
    public let kind: AdmissionEventKind
    public let occurredAt: Date

    public init(automationID: AutomationID, automationName: String, kind: AdmissionEventKind, occurredAt: Date) {
        self.automationID = automationID
        self.automationName = automationName
        self.kind = kind
        self.occurredAt = occurredAt
    }
}

public struct RunCoordinatorStatus: Sendable, Equatable {
    public let isPaused: Bool
    public let isSessionReady: Bool
    public let isRunning: Bool
    public let queuedCount: Int
    public let currentName: String?
    public let recentEvents: [AdmissionEvent]

    public init(
        isPaused: Bool,
        isSessionReady: Bool,
        isRunning: Bool,
        queuedCount: Int,
        currentName: String?,
        recentEvents: [AdmissionEvent]
    ) {
        self.isPaused = isPaused
        self.isSessionReady = isSessionReady
        self.isRunning = isRunning
        self.queuedCount = queuedCount
        self.currentName = currentName
        self.recentEvents = recentEvents
    }
}

public typealias RunExecution = @Sendable (AutomationDefinition, UUID) async -> RunRecord

public actor RunCoordinator {
    public struct Limits: Sendable, Equatable {
        public var maximumQueuedRuns: Int
        public var automaticQueueExpiration: TimeInterval
        public var automaticCooldown: TimeInterval

        public init(
            maximumQueuedRuns: Int = 10,
            automaticQueueExpiration: TimeInterval = 30,
            automaticCooldown: TimeInterval = 10
        ) {
            self.maximumQueuedRuns = maximumQueuedRuns
            self.automaticQueueExpiration = automaticQueueExpiration
            self.automaticCooldown = automaticCooldown
        }

        public static let `default` = Limits()
    }

    private struct QueuedRun: Sendable {
        let definition: AutomationDefinition
        let source: RunRequestSource
        let id: UUID
        let requestedAt: Date
    }

    private struct ActiveRun: Sendable {
        let automationID: AutomationID
        let name: String
        let isAutomatic: Bool
    }

    public static let maximumEventLog = 100

    private let clock: CoreClock
    private let limits: Limits
    private let execution: RunExecution
    private let maximumEventLog: Int

    private var queue: [QueuedRun] = []
    private var activeRun: ActiveRun?
    private var isPaused = false
    private var isSessionReady = true
    private var isProcessing = false
    private var lastAutomaticAdmission: [AutomationID: Date] = [:]
    private var eventLog: [AdmissionEvent] = []
    private var processTask: Task<Void, Never>?
    private var idleWaiters: [CheckedContinuation<Void, Never>] = []

    public init(
        clock: CoreClock,
        limits: Limits = .default,
        maximumEventLog: Int = RunCoordinator.maximumEventLog,
        execution: @escaping RunExecution
    ) {
        self.clock = clock
        self.limits = limits
        self.maximumEventLog = maximumEventLog
        self.execution = execution
    }

    @discardableResult
    public func submit(
        _ definition: AutomationDefinition,
        source: RunRequestSource = .manual,
        id: UUID = UUID()
    ) -> AdmissionOutcome {
        let now = clock.now()

        let validation = definition.validate()
        guard validation.isValid else {
            return .rejected(validation.errors.first?.message ?? "The workflow is not valid.")
        }

        if source.isAutomatic {
            if !isSessionReady {
                return .suppressedSessionNotReady
            }
            if isPaused {
                return .suppressedPaused
            }
            if isDuplicateAutomatic(definition.id) {
                appendEvent(.duplicateSuppressed, definition: definition, at: now)
                return .suppressedDuplicate
            }
            if let last = lastAutomaticAdmission[definition.id],
               now.timeIntervalSince(last) < limits.automaticCooldown {
                appendEvent(.cooldownSuppressed, definition: definition, at: now)
                return .suppressedCooldown
            }
            if queue.count >= limits.maximumQueuedRuns {
                appendEvent(.queueOverflow, definition: definition, at: now)
                return .queueFull
            }
            lastAutomaticAdmission[definition.id] = now
        } else if queue.count >= limits.maximumQueuedRuns {
            appendEvent(.queueOverflow, definition: definition, at: now)
            return .queueFull
        }

        let wasIdle = !isProcessing
        queue.append(QueuedRun(definition: definition, source: source, id: id, requestedAt: now))
        startProcessingIfNeeded()
        return wasIdle ? .started : .queued
    }

    public func pauseAutomaticTriggers() {
        isPaused = true
        let now = clock.now()
        let cleared = queue.filter { $0.source.isAutomatic }
        queue.removeAll { $0.source.isAutomatic }
        for run in cleared {
            appendEvent(.pausedCleared, run: run, at: now)
        }
    }

    public func resumeAutomaticTriggers() {
        isPaused = false
    }

    public func updateSessionReadiness(_ ready: Bool) {
        isSessionReady = ready
        guard !ready else { return }

        let now = clock.now()
        let cleared = queue
        queue.removeAll()
        for run in cleared {
            appendEvent(.sleepInterrupted, run: run, at: now)
        }
        processTask?.cancel()
    }

    public func cancelAll() {
        queue.removeAll()
        processTask?.cancel()
        resumeIdleWaitersIfNeeded()
    }

    public func status() -> RunCoordinatorStatus {
        RunCoordinatorStatus(
            isPaused: isPaused,
            isSessionReady: isSessionReady,
            isRunning: activeRun != nil,
            queuedCount: queue.count,
            currentName: activeRun?.name,
            recentEvents: eventLog
        )
    }

    public func waitUntilIdle() async {
        if queue.isEmpty, !isProcessing {
            return
        }
        await withCheckedContinuation { continuation in
            idleWaiters.append(continuation)
        }
    }

    private func isDuplicateAutomatic(_ id: AutomationID) -> Bool {
        if let activeRun, activeRun.isAutomatic, activeRun.automationID == id {
            return true
        }
        return queue.contains { $0.source.isAutomatic && $0.definition.id == id }
    }

    private func startProcessingIfNeeded() {
        guard !isProcessing, !queue.isEmpty else { return }
        isProcessing = true
        processTask = Task { await self.processQueue() }
    }

    private func processQueue() async {
        while !queue.isEmpty {
            let now = clock.now()
            let next = queue.removeFirst()

            if next.source.isAutomatic,
               now.timeIntervalSince(next.requestedAt) > limits.automaticQueueExpiration {
                appendEvent(.expired, run: next, at: now)
                continue
            }

            activeRun = ActiveRun(
                automationID: next.definition.id,
                name: next.definition.name,
                isAutomatic: next.source.isAutomatic
            )
            _ = await execution(next.definition, next.id)
            activeRun = nil
        }

        isProcessing = false
        processTask = nil
        resumeIdleWaitersIfNeeded()
    }

    private func resumeIdleWaitersIfNeeded() {
        guard queue.isEmpty, !isProcessing else { return }
        let waiters = idleWaiters
        idleWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func appendEvent(_ kind: AdmissionEventKind, run: QueuedRun, at date: Date) {
        appendEvent(
            AdmissionEvent(
                automationID: run.definition.id,
                automationName: run.definition.name,
                kind: kind,
                occurredAt: date
            )
        )
    }

    private func appendEvent(_ kind: AdmissionEventKind, definition: AutomationDefinition, at date: Date) {
        appendEvent(
            AdmissionEvent(
                automationID: definition.id,
                automationName: definition.name,
                kind: kind,
                occurredAt: date
            )
        )
    }

    private func appendEvent(_ event: AdmissionEvent) {
        eventLog.append(event)
        if eventLog.count > maximumEventLog {
            eventLog.removeFirst(eventLog.count - maximumEventLog)
        }
    }
}
