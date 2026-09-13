import Foundation

public enum ComposerActionDraft: Codable, Hashable, Sendable {
    case openApplication(name: String, resolved: ResourceReference?)
    case hideApplication(name: String, resolved: ResourceReference?)
    case quitApplication(name: String, resolved: ResourceReference?)
    case openFile(target: FileTarget?)
    case revealInFinder(target: FileTarget?)
    case openWebsite(url: String, browser: ResourceReference?)
    case arrangeWindow(name: String, resolved: ResourceReference?, preset: WindowPreset, display: WindowDisplaySelection)
    case wait(TimeInterval)
    case showNotification(title: String, message: String)
    case copyText(String)
}

public enum ComposerTriggerDraft: Codable, Hashable, Sendable {
    case manual
    case daily(hour: Int, minute: Int)
    case weekdays(Set<Weekday>, hour: Int, minute: Int)
    case interval(TimeInterval)
    case relative(TimeInterval)
    case once(hour: Int, minute: Int)
    case oneTime(Date)
    case applicationLifecycle(application: ResourceReference?, label: String, event: LifecycleEvent)
    case wake
    case displayConnection(event: DisplayEvent, selection: DisplaySelection)
    case externalVolume(event: VolumeEvent, selection: VolumeSelection)
    case powerSource(PowerEvent)
    case batteryThreshold(comparator: ThresholdComparison, percentage: Int)
}

extension ComposerActionDraft {
    public init(_ action: ActionConfiguration) {
        switch action {
        case .openApplication(let value):
            self = .openApplication(name: value.application.label, resolved: Self.resolved(value.application))
        case .hideApplication(let value):
            self = .hideApplication(name: value.application.label, resolved: Self.resolved(value.application))
        case .quitApplication(let value):
            self = .quitApplication(name: value.application.label, resolved: Self.resolved(value.application))
        case .openFile(let value):
            self = .openFile(target: Self.resolved(value.target))
        case .revealInFinder(let value):
            self = .revealInFinder(target: Self.resolved(value.target))
        case .openWebsite(let value):
            self = .openWebsite(url: value.url, browser: value.browser.flatMap(Self.resolved))
        case .arrangeWindow(let value):
            self = .arrangeWindow(
                name: value.application.label,
                resolved: Self.resolved(value.application),
                preset: value.preset,
                display: value.display
            )
        case .wait(let value):
            self = .wait(value.duration)
        case .showNotification(let value):
            self = .showNotification(title: value.title, message: value.message)
        case .copyText(let value):
            self = .copyText(value.text)
        }
    }

    private static func resolved(_ reference: ResourceReference) -> ResourceReference? {
        reference.identifier.isEmpty ? nil : reference
    }

    private static func resolved(_ target: FileTarget) -> FileTarget? {
        target.path.isEmpty ? nil : target
    }
}

extension ComposerTriggerDraft {
    public init(_ trigger: TriggerConfiguration) {
        switch trigger {
        case .manual:
            self = .manual
        case .schedule(let schedule):
            switch schedule {
            case .daily(let hour, let minute):
                self = .daily(hour: hour, minute: minute)
            case .weekdays(let days, let hour, let minute):
                self = .weekdays(days, hour: hour, minute: minute)
            case .interval(let every, _):
                self = .interval(every)
            case .oneTime(let date):
                self = .oneTime(date)
            }
        case .applicationLifecycle(let value):
            self = .applicationLifecycle(
                application: value.application,
                label: value.application.label,
                event: value.event
            )
        case .wake:
            self = .wake
        case .displayConnection(let value):
            self = .displayConnection(event: value.event, selection: value.selection)
        case .externalVolume(let value):
            self = .externalVolume(event: value.event, selection: value.selection)
        case .powerSource(let value):
            self = .powerSource(value.event)
        case .batteryThreshold(let value):
            self = .batteryThreshold(comparator: value.comparator, percentage: value.percentage)
        }
    }
}

public struct ComposerAction: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let draft: ComposerActionDraft

    public init(id: UUID = UUID(), draft: ComposerActionDraft) {
        self.id = id
        self.draft = draft
    }
}

public enum ComposerElement: Codable, Hashable, Sendable {
    case action(ComposerAction)
    case unresolved(String)
}

public struct AuthoringNode: Codable, Hashable, Sendable {
    public let id: UUID
    public let draft: ComposerActionDraft

    public init(id: UUID, draft: ComposerActionDraft) {
        self.id = id
        self.draft = draft
    }
}

public struct AuthoringSnapshot: Codable, Hashable, Sendable {
    public static let currentVersion = 2

    public let version: Int
    public let text: String
    public let trigger: ComposerTriggerDraft
    public let nodes: [AuthoringNode]
    public let resolution: ScheduleResolution
    public let revision: WorkflowRevision
    public let rationaleText: String?

    public init(
        version: Int = AuthoringSnapshot.currentVersion,
        text: String,
        trigger: ComposerTriggerDraft,
        nodes: [AuthoringNode],
        resolution: ScheduleResolution,
        revision: WorkflowRevision,
        rationaleText: String? = nil
    ) {
        self.version = version
        self.text = text
        self.trigger = trigger
        self.nodes = nodes
        self.resolution = resolution
        self.revision = revision
        self.rationaleText = rationaleText
    }
}

public struct ScheduleResolution: Codable, Hashable, Sendable {
    public var oneTimeDate: Date?
    public var intervalAnchor: Date?
    public var timeZoneIdentifier: String?

    public init(
        oneTimeDate: Date? = nil,
        intervalAnchor: Date? = nil,
        timeZoneIdentifier: String? = nil
    ) {
        self.oneTimeDate = oneTimeDate
        self.intervalAnchor = intervalAnchor
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public static let empty = ScheduleResolution()

    public var isEmpty: Bool {
        oneTimeDate == nil && intervalAnchor == nil
    }
}

public struct ComposerDocument: Sendable {
    private struct Snapshot: Sendable {
        let text: String
        let trigger: ComposerTriggerDraft
        let elements: [ComposerElement]
        let parseOutcome: ParseOutcome
        let diagnostics: [ParseDiagnostic]
        let revision: WorkflowRevision
        let resolution: ScheduleResolution
        let rationaleText: String?
    }

    private final class ResolutionBox: @unchecked Sendable {
        var value = ScheduleResolution.empty
    }

    private let parser = CommandParser()
    private static let historyLimit = 100
    private static let language = CommandLanguageCatalog.standard
    private let resolution = ResolutionBox()

    public let clock: CoreClock
    public private(set) var text: String
    public private(set) var trigger: ComposerTriggerDraft
    public private(set) var elements: [ComposerElement]
    public private(set) var parseOutcome: ParseOutcome
    public private(set) var diagnostics: [ParseDiagnostic]
    public private(set) var revision: WorkflowRevision
    public private(set) var rationaleText: String? = nil

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    public var scheduleResolution: ScheduleResolution {
        resolution.value
    }

    public init(text: String = "", clock: CoreClock = SystemClock()) {
        self.clock = clock
        self.text = text
        self.trigger = .manual
        self.elements = []
        self.parseOutcome = .needsInput
        self.diagnostics = []
        self.revision = WorkflowRevision(1)
        applyText(text)
    }

    public init(trigger: ComposerTriggerDraft, actions: [ComposerActionDraft], clock: CoreClock = SystemClock()) {
        self.clock = clock
        self.text = ""
        self.trigger = trigger
        self.elements = actions.map { .action(ComposerAction(draft: $0)) }
        self.parseOutcome = .needsInput
        self.diagnostics = []
        self.revision = WorkflowRevision(1)
        adoptScheduleResolution(from: trigger)
        self.text = renderedText()
    }

    public init(definition: AutomationDefinition, clock: CoreClock = SystemClock()) {
        self.clock = clock
        self.text = ""
        self.trigger = ComposerTriggerDraft(definition.trigger)
        self.elements = definition.actions.map { .action(ComposerAction(draft: ComposerActionDraft($0))) }
        self.parseOutcome = .needsInput
        self.diagnostics = []
        self.revision = WorkflowRevision(1)
        adoptScheduleResolution(from: definition.trigger)
        self.text = renderedText()
    }

    public var actions: [ComposerAction] {
        elements.compactMap { element in
            if case .action(let action) = element {
                return action
            }
            return nil
        }
    }

    public var unresolvedTexts: [String] {
        elements.compactMap { element in
            if case .unresolved(let value) = element {
                return value
            }
            return nil
        }
    }

    public var hasUnresolvedText: Bool {
        !unresolvedTexts.isEmpty
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public var hasUnresolvedApplications: Bool {
        actions.contains { action in
            switch action.draft {
            case .openApplication(_, let resolved):
                return resolved == nil
            case .hideApplication(_, let resolved):
                return resolved == nil
            case .quitApplication(_, let resolved):
                return resolved == nil
            case .arrangeWindow(_, let resolved, _, _):
                return resolved == nil
            default:
                return false
            }
        }
    }

    public var hasUnresolvedWebsites: Bool {
        actions.contains { action in
            if case .openWebsite(let url, _) = action.draft {
                return !OpenWebsiteAction.isAbsoluteHTTPURL(url)
            }
            return false
        }
    }

    public var hasUnresolvedCopyText: Bool {
        actions.contains { action in
            if case .copyText(let value) = action.draft {
                return value.isEmpty
            }
            return false
        }
    }

    public var hasUnresolvedFiles: Bool {
        actions.contains { action in
            switch action.draft {
            case .openFile(let target), .revealInFinder(let target):
                return target == nil
            default:
                return false
            }
        }
    }

    public var hasUnresolvedActions: Bool {
        hasUnresolvedApplications || hasUnresolvedWebsites || hasUnresolvedCopyText || hasUnresolvedFiles
    }

    public var hasUnresolvedTrigger: Bool {
        if case .applicationLifecycle(let application, let label, _) = trigger {
            return application == nil || label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    public var blockingParseMessage: String? {
        guard parseOutcome != .complete else { return nil }
        return diagnostics.first { $0.severity == .error }?.message
    }

    public mutating func setText(_ newText: String) {
        guard newText != text else { return }
        recordHistory()
        applyText(newText)
        bumpRevision()
    }

    public func completionFragmentRange() -> SourceSpan {
        SourceSpan(start: trailingFragmentStart(), end: text.utf16.count)
    }

    public mutating func accept(_ suggestion: Suggestion, replacing replacementSpan: SourceSpan? = nil) {
        let span: SourceSpan
        if let replacementSpan, replacementSpan.isValid(in: text) {
            span = replacementSpan
        } else {
            span = completionFragmentRange()
        }

        var prefix = text.substring(in: SourceSpan(start: 0, end: span.start)) ?? ""
        if !prefix.isEmpty, let last = prefix.last, !last.isWhitespace {
            prefix.append(" ")
        }
        setText(prefix + suggestion.phrase)
    }

    public mutating func addAction(_ draft: ComposerActionDraft) {
        recordHistory()
        elements.append(.action(ComposerAction(draft: draft)))
        text = renderedText()
        bumpRevision()
    }

    public mutating func removeAction(id: UUID) {
        guard let index = elements.firstIndex(where: { element in
            if case .action(let action) = element { return action.id == id }
            return false
        }) else {
            return
        }
        recordHistory()
        elements.remove(at: index)
        text = renderedText()
        bumpRevision()
    }

    public mutating func updateAction(id: UUID, draft: ComposerActionDraft) {
        guard let index = elements.firstIndex(where: { element in
            if case .action(let action) = element { return action.id == id }
            return false
        }) else {
            return
        }
        recordHistory()
        elements[index] = .action(ComposerAction(id: id, draft: draft))
        text = renderedText()
        bumpRevision()
    }

    public mutating func replaceActions(ids: [UUID], with drafts: [ComposerActionDraft]) {
        guard !ids.isEmpty, !drafts.isEmpty else { return }

        let idSet = Set(ids)
        let positions = elements.indices.filter { index in
            guard case .action(let action) = elements[index] else { return false }
            return idSet.contains(action.id)
        }
        guard !positions.isEmpty else { return }

        recordHistory()
        let positionSet = Set(positions)
        var updated: [ComposerElement] = []
        var replaced = false
        for index in elements.indices {
            if positionSet.contains(index) {
                if !replaced {
                    updated.append(contentsOf: drafts.map { .action(ComposerAction(draft: $0)) })
                    replaced = true
                }
                continue
            }
            updated.append(elements[index])
        }
        elements = updated
        text = renderedText()
        bumpRevision()
    }

    public mutating func resolveApplication(id: UUID, reference: ResourceReference) {
        guard let action = action(id: id) else { return }
        switch action.draft {
        case .openApplication(let name, _):
            updateAction(id: id, draft: .openApplication(name: name, resolved: reference))
        case .hideApplication(let name, _):
            updateAction(id: id, draft: .hideApplication(name: name, resolved: reference))
        case .quitApplication(let name, _):
            updateAction(id: id, draft: .quitApplication(name: name, resolved: reference))
        case .arrangeWindow(let name, _, let preset, let display):
            updateAction(id: id, draft: .arrangeWindow(name: name, resolved: reference, preset: preset, display: display))
        default:
            break
        }
    }

    public mutating func setWebsiteBrowser(id: UUID, browser: ResourceReference?) {
        guard case .openWebsite(let url, _) = action(id: id)?.draft else { return }
        updateAction(id: id, draft: .openWebsite(url: url, browser: browser))
    }

    public mutating func moveActionUp(id: UUID) {
        guard let position = actionPosition(of: id), position > 0 else { return }
        recordHistory()
        elements.swapAt(position, previousElementIndex(before: position))
        text = renderedText()
        bumpRevision()
    }

    public mutating func moveActionDown(id: UUID) {
        guard let position = actionPosition(of: id), position < elements.count - 1 else { return }
        recordHistory()
        elements.swapAt(position, nextElementIndex(after: position))
        text = renderedText()
        bumpRevision()
    }

    public mutating func moveActions(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let slots = elements.indices.filter { index in
            if case .action = elements[index] { return true }
            return false
        }
        let current = slots.map { elements[$0] }
        let reordered = Self.reordered(current, fromOffsets: offsets, toOffset: destination)
        guard reordered != current else { return }
        recordHistory()
        for (slot, element) in zip(slots, reordered) {
            elements[slot] = element
        }
        text = renderedText()
        bumpRevision()
    }

    private static func reordered<T: Equatable>(_ items: [T], fromOffsets offsets: IndexSet, toOffset destination: Int) -> [T] {
        guard !offsets.isEmpty else { return items }
        let moving = offsets.sorted().compactMap { items.indices.contains($0) ? items[$0] : nil }
        guard !moving.isEmpty else { return items }
        var result = items
        for index in offsets.sorted(by: >) where result.indices.contains(index) {
            result.remove(at: index)
        }
        let removedBefore = offsets.filter { $0 < destination }.count
        let insertion = max(0, min(destination - removedBefore, result.count))
        result.insert(contentsOf: moving, at: insertion)
        return result
    }

    public mutating func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot())
        restore(snapshot)
    }

    public mutating func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot())
        restore(snapshot)
    }

    public func renderedText() -> String {
        let joiner = Self.language.shared.actionJoiner
        let actionText = elements.map(Self.render).joined(separator: joiner)
        let triggerText = Self.render(trigger)
        let body: String
        if triggerText.isEmpty {
            body = actionText
        } else if actionText.isEmpty {
            body = triggerText
        } else {
            body = triggerText + joiner + actionText
        }

        if let rationaleText, !rationaleText.isEmpty {
            return body.isEmpty ? rationaleText : body + " " + rationaleText
        }
        return body
    }

    public func resolvedActions() -> [ActionConfiguration]? {
        var result: [ActionConfiguration] = []
        for element in elements {
            guard case .action(let action) = element else { continue }
            switch action.draft {
            case .openApplication(_, let resolved):
                guard let resolved else { return nil }
                result.append(.openApplication(OpenApplicationAction(application: resolved)))
            case .hideApplication(_, let resolved):
                guard let resolved else { return nil }
                result.append(.hideApplication(HideApplicationAction(application: resolved)))
            case .quitApplication(_, let resolved):
                guard let resolved else { return nil }
                result.append(.quitApplication(QuitApplicationAction(application: resolved)))
            case .openFile(let target):
                guard let target else { return nil }
                result.append(.openFile(OpenFileAction(target: target)))
            case .revealInFinder(let target):
                guard let target else { return nil }
                result.append(.revealInFinder(RevealInFinderAction(target: target)))
            case .openWebsite(let url, let browser):
                guard OpenWebsiteAction.isAbsoluteHTTPURL(url) else { return nil }
                result.append(.openWebsite(OpenWebsiteAction(url: url, browser: browser)))
            case .arrangeWindow(_, let resolved, let preset, let display):
                guard let resolved else { return nil }
                result.append(.arrangeWindow(ArrangeWindowAction(application: resolved, preset: preset, display: display)))
            case .wait(let duration):
                result.append(.wait(WaitAction(duration: duration)))
            case .showNotification(let title, let message):
                result.append(.showNotification(ShowNotificationAction(title: title, message: message)))
            case .copyText(let value):
                guard !value.isEmpty else { return nil }
                result.append(.copyText(CopyTextAction(text: value)))
            }
        }
        return result
    }

    public func makeDefinition(
        name: String,
        id: AutomationID = AutomationID(),
        revision: WorkflowRevision = WorkflowRevision(1)
    ) -> AutomationDefinition? {
        makeDefinition(name: name, id: id, revision: revision, now: clock.now(), calendar: .current)
    }

    public func makeDefinition(
        name: String,
        id: AutomationID = AutomationID(),
        revision: WorkflowRevision = WorkflowRevision(1),
        now: Date,
        calendar: Calendar = .current
    ) -> AutomationDefinition? {
        resolveSchedule(now: now, calendar: calendar)
        guard !hasUnresolvedText else { return nil }
        guard let actions = resolvedActions(), !actions.isEmpty else { return nil }
        guard let triggerConfiguration = triggerConfiguration() else { return nil }
        let definition = AutomationDefinition(
            id: id,
            name: name,
            revision: revision,
            trigger: triggerConfiguration,
            actions: actions
        )
        return definition.validate(relativeTo: now).isValid ? definition : nil
    }

    public func triggerConfiguration() -> TriggerConfiguration? {
        switch trigger {
        case .manual:
            return .manual(ManualTrigger())
        case .daily(let hour, let minute):
            return .schedule(.daily(hour: hour, minute: minute))
        case .weekdays(let days, let hour, let minute):
            return .schedule(.weekdays(days, hour: hour, minute: minute))
        case .interval(let seconds):
            guard let anchor = resolution.value.intervalAnchor else { return nil }
            return .schedule(.interval(every: seconds, startingAt: anchor))
        case .relative:
            guard let date = resolution.value.oneTimeDate else { return nil }
            return .schedule(.oneTime(date))
        case .once:
            guard let date = resolution.value.oneTimeDate else { return nil }
            return .schedule(.oneTime(date))
        case .oneTime(let date):
            return .schedule(.oneTime(date))
        case .applicationLifecycle(let application, let label, let event):
            let reference = application
                ?? ResourceReference(kind: .application, identifier: "", label: label)
            return .applicationLifecycle(ApplicationLifecycleTrigger(application: reference, event: event))
        case .wake:
            return .wake(WakeTrigger())
        case .displayConnection(let event, let selection):
            return .displayConnection(DisplayConnectionTrigger(selection: selection, event: event))
        case .externalVolume(let event, let selection):
            return .externalVolume(ExternalVolumeTrigger(selection: selection, event: event))
        case .powerSource(let event):
            return .powerSource(PowerSourceTrigger(event: event))
        case .batteryThreshold(let comparator, let percentage):
            return .batteryThreshold(BatteryThresholdTrigger(comparator: comparator, percentage: percentage))
        }
    }

    public func triggerConfiguration(relativeTo now: Date, calendar: Calendar = .current) -> TriggerConfiguration? {
        resolveSchedule(now: now, calendar: calendar)
        return triggerConfiguration()
    }

    public func resolveSchedule(now: Date, calendar: Calendar) {
        resolution.value.timeZoneIdentifier = calendar.timeZone.identifier
        switch trigger {
        case .relative(let seconds):
            if resolution.value.oneTimeDate == nil {
                resolution.value.oneTimeDate = now.addingTimeInterval(seconds)
            }
        case .once(let hour, let minute):
            if resolution.value.oneTimeDate == nil {
                resolution.value.oneTimeDate = calendar.nextDate(
                    after: now.addingTimeInterval(-1),
                    matching: DateComponents(hour: hour, minute: minute, second: 0),
                    matchingPolicy: .nextTime,
                    repeatedTimePolicy: .first,
                    direction: .forward
                )
            }
        case .oneTime(let date):
            resolution.value.oneTimeDate = date
        case .interval:
            if resolution.value.intervalAnchor == nil {
                resolution.value.intervalAnchor = now
            }
        case .manual, .daily, .weekdays,
             .applicationLifecycle, .wake, .displayConnection,
             .externalVolume, .powerSource, .batteryThreshold:
            resolution.value.oneTimeDate = nil
            resolution.value.intervalAnchor = nil
        }
    }

    public func clearScheduleResolution() {
        resolution.value = .empty
    }

    public func makeSnapshot() -> AuthoringSnapshot {
        AuthoringSnapshot(
            text: text,
            trigger: trigger,
            nodes: actions.map { AuthoringNode(id: $0.id, draft: $0.draft) },
            resolution: resolution.value,
            revision: revision,
            rationaleText: rationaleText
        )
    }

    public init?(snapshot: AuthoringSnapshot, clock: CoreClock = SystemClock()) {
        guard snapshot.version == AuthoringSnapshot.currentVersion else {
            return nil
        }
        self.clock = clock
        self.text = snapshot.text
        self.trigger = snapshot.trigger
        self.elements = snapshot.nodes.map { .action(ComposerAction(id: $0.id, draft: $0.draft)) }
        self.parseOutcome = .needsInput
        self.diagnostics = []
        self.revision = snapshot.revision
        self.resolution.value = snapshot.resolution
        self.rationaleText = snapshot.rationaleText
    }

    private func adoptScheduleResolution(from configuration: TriggerConfiguration) {
        switch configuration {
        case .schedule(.oneTime(let date)):
            resolution.value.oneTimeDate = date
        case .schedule(.interval(_, let startingAt)):
            resolution.value.intervalAnchor = startingAt
        default:
            break
        }
    }

    private func adoptScheduleResolution(from draft: ComposerTriggerDraft) {
        switch draft {
        case .oneTime(let date):
            resolution.value.oneTimeDate = date
        default:
            break
        }
    }

    public mutating func setTrigger(_ draft: ComposerTriggerDraft) {
        guard draft != trigger else { return }
        recordHistory()
        clearScheduleResolution()
        trigger = draft
        text = renderedText()
        bumpRevision()
    }

    private func action(id: UUID) -> ComposerAction? {
        actions.first { $0.id == id }
    }

    private func actionPosition(of id: UUID) -> Int? {
        elements.firstIndex { element in
            if case .action(let action) = element { return action.id == id }
            return false
        }
    }

    private func previousElementIndex(before index: Int) -> Int {
        index - 1
    }

    private func nextElementIndex(after index: Int) -> Int {
        index + 1
    }

    private mutating func applyText(_ newText: String) {
        text = newText
        rationaleText = Self.language.rationaleText(in: newText)
        let parsed = parser.parse(newText)
        parseOutcome = parsed.outcome
        diagnostics = parsed.diagnostics
        reconcileElements(from: parsed)
    }

    private mutating func reconcileElements(from parsed: ParsedCommand) {
        let previousActions = actions

        var previousCounts: [ActionShape: Int] = [:]
        for action in previousActions where !Self.isTextIdentifiable(action.draft) {
            previousCounts[Self.shape(of: action.draft), default: 0] += 1
        }
        var newCounts: [ActionShape: Int] = [:]
        for clause in parsed.clauses {
            for draft in Self.actionDrafts(from: clause) where !Self.isTextIdentifiable(draft) {
                newCounts[Self.shape(of: draft), default: 0] += 1
            }
        }
        var ambiguousShapes: Set<ActionShape> = []
        for shape in Set(previousCounts.keys).union(newCounts.keys)
        where previousCounts[shape, default: 0] != newCounts[shape, default: 0] {
            ambiguousShapes.insert(shape)
        }

        var consumed: Set<Int> = []
        var newElements: [ComposerElement] = []
        var newTrigger: ComposerTriggerDraft = .manual

        let triggerIndices = parsed.clauses.indices.filter { Self.isTriggerClause(parsed.clauses[$0]) }
        let triggerAllowed = triggerIndices.count == 0
            || (triggerIndices.count == 1
                && (triggerIndices[0] == 0 || triggerIndices[0] == parsed.clauses.count - 1))

        for clause in parsed.clauses {
            if Self.isTriggerClause(clause), !triggerAllowed {
                newElements.append(.unresolved(clauseText(clause)))
                continue
            }

            switch clause.kind {
            case .applicationLifecycle:
                let name = (clause.lifecycleApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let event = clause.lifecycleEvent, !name.isEmpty {
                    newTrigger = .applicationLifecycle(application: nil, label: name, event: event)
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .wake:
                newTrigger = .wake

            case .displayConnection:
                if let event = clause.displayEvent {
                    newTrigger = .displayConnection(event: event, selection: .anyExternal)
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .externalVolume:
                if let event = clause.volumeEvent {
                    newTrigger = .externalVolume(event: event, selection: .anyExternal)
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .powerSource:
                if let event = clause.powerEvent {
                    newTrigger = .powerSource(event)
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .batteryThreshold:
                if let threshold = clause.batteryThreshold {
                    newTrigger = .batteryThreshold(comparator: threshold.comparator, percentage: threshold.percentage)
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .schedule:
                switch clause.schedule {
                case .daily(let hour, let minute):
                    newTrigger = .daily(hour: hour, minute: minute)
                case .weekdays(let days, let hour, let minute):
                    newTrigger = .weekdays(days, hour: hour, minute: minute)
                case .interval(let seconds):
                    newTrigger = .interval(seconds)
                case .relative(let seconds):
                    newTrigger = .relative(seconds)
                case .once(let hour, let minute):
                    newTrigger = .once(hour: hour, minute: minute)
                case .absolute(let year, let month, let day, let hour, let minute):
                    let components = DateComponents(
                        year: year,
                        month: month,
                        day: day,
                        hour: hour,
                        minute: minute
                    )
                    if let date = Calendar.current.date(from: components) {
                        newTrigger = .oneTime(date)
                    } else {
                        newElements.append(.unresolved(clauseText(clause)))
                    }
                case .incomplete, .none:
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .openApplication:
                for name in clause.resourceNames {
                    let draft: ComposerActionDraft
                    if ResourceNameHeuristics.isWebsite(name) {
                        draft = .openWebsite(url: name, browser: nil)
                    } else {
                        draft = .openApplication(name: name, resolved: nil)
                    }
                    newElements.append(.action(reusedAction(for: draft, from: previousActions, consumed: &consumed)))
                }

            case .hideApplication:
                for name in clause.resourceNames {
                    newElements.append(
                        .action(reusedAction(for: .hideApplication(name: name, resolved: nil), from: previousActions, consumed: &consumed))
                    )
                }

            case .quitApplication:
                for name in clause.resourceNames {
                    newElements.append(
                        .action(reusedAction(for: .quitApplication(name: name, resolved: nil), from: previousActions, consumed: &consumed))
                    )
                }

            case .openFile:
                newElements.append(
                    .action(
                        reusedAction(
                            for: .openFile(target: nil),
                            from: previousActions,
                            consumed: &consumed,
                            ambiguousShapes: ambiguousShapes
                        )
                    )
                )

            case .revealInFinder:
                newElements.append(
                    .action(
                        reusedAction(
                            for: .revealInFinder(target: nil),
                            from: previousActions,
                            consumed: &consumed,
                            ambiguousShapes: ambiguousShapes
                        )
                    )
                )

            case .arrangeWindow:
                let name = (clause.arrangeApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let preset = clause.arrangePreset, !name.isEmpty {
                    let draft = ComposerActionDraft.arrangeWindow(
                        name: name,
                        resolved: nil,
                        preset: preset,
                        display: .current
                    )
                    newElements.append(.action(reusedAction(for: draft, from: previousActions, consumed: &consumed)))
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .wait:
                if let duration = clause.duration, WaitAction.allowedRange.contains(duration) {
                    newElements.append(.action(reusedAction(for: .wait(duration), from: previousActions, consumed: &consumed)))
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .showNotification:
                newElements.append(
                    .action(
                        reusedAction(
                            for: .showNotification(title: "TaskOS", message: ""),
                            from: previousActions,
                            consumed: &consumed,
                            ambiguousShapes: ambiguousShapes
                        )
                    )
                )

            case .copyText:
                let literal = clause.copyText ?? ""
                if literal.isEmpty {
                    newElements.append(.unresolved(clauseText(clause)))
                } else {
                    newElements.append(.action(reusedAction(for: .copyText(literal), from: previousActions, consumed: &consumed)))
                }

            case .unsupported, .unrecognized:
                newElements.append(.unresolved(clauseText(clause)))
            }
        }

        if newTrigger != trigger {
            clearScheduleResolution()
        }
        elements = newElements
        trigger = newTrigger
    }

    private static func isTriggerClause(_ clause: ParsedClause) -> Bool {
        switch clause.kind {
        case .schedule, .applicationLifecycle, .wake, .displayConnection,
             .externalVolume, .powerSource, .batteryThreshold:
            return true
        default:
            return false
        }
    }

    private func reusedAction(
        for draft: ComposerActionDraft,
        from previous: [ComposerAction],
        consumed: inout Set<Int>,
        ambiguousShapes: Set<ActionShape> = []
    ) -> ComposerAction {
        if !Self.isTextIdentifiable(draft), ambiguousShapes.contains(Self.shape(of: draft)) {
            return ComposerAction(draft: draft)
        }
        if let index = previous.indices.first(where: {
            !consumed.contains($0) && Self.matchesExactly(previous[$0].draft, draft)
        }) {
            consumed.insert(index)
            return ComposerAction(id: previous[index].id, draft: merge(previous: previous[index].draft, new: draft))
        }
        if let index = previous.indices.first(where: {
            !consumed.contains($0) && Self.sameCase(previous[$0].draft, draft)
        }) {
            consumed.insert(index)
            return ComposerAction(id: previous[index].id, draft: merge(previous: previous[index].draft, new: draft))
        }
        return ComposerAction(draft: draft)
    }

    private enum ActionShape: Hashable {
        case openApplication
        case hideApplication
        case quitApplication
        case openFile
        case revealInFinder
        case openWebsite
        case arrangeWindow
        case wait
        case showNotification
        case copyText
    }

    private static func shape(of draft: ComposerActionDraft) -> ActionShape {
        switch draft {
        case .openApplication: return .openApplication
        case .hideApplication: return .hideApplication
        case .quitApplication: return .quitApplication
        case .openFile: return .openFile
        case .revealInFinder: return .revealInFinder
        case .openWebsite: return .openWebsite
        case .arrangeWindow: return .arrangeWindow
        case .wait: return .wait
        case .showNotification: return .showNotification
        case .copyText: return .copyText
        }
    }

    private static func isTextIdentifiable(_ draft: ComposerActionDraft) -> Bool {
        switch draft {
        case .openFile, .revealInFinder, .showNotification:
            return false
        default:
            return true
        }
    }

    private static func actionDrafts(from clause: ParsedClause) -> [ComposerActionDraft] {
        switch clause.kind {
        case .openApplication:
            return clause.resourceNames.map { name in
                if ResourceNameHeuristics.isWebsite(name) {
                    return .openWebsite(url: name, browser: nil)
                }
                return .openApplication(name: name, resolved: nil)
            }
        case .hideApplication:
            return clause.resourceNames.map { .hideApplication(name: $0, resolved: nil) }
        case .quitApplication:
            return clause.resourceNames.map { .quitApplication(name: $0, resolved: nil) }
        case .openFile:
            return [.openFile(target: nil)]
        case .revealInFinder:
            return [.revealInFinder(target: nil)]
        case .arrangeWindow:
            let name = (clause.arrangeApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard let preset = clause.arrangePreset, !name.isEmpty else { return [] }
            return [.arrangeWindow(name: name, resolved: nil, preset: preset, display: .current)]
        case .wait:
            guard let duration = clause.duration, WaitAction.allowedRange.contains(duration) else { return [] }
            return [.wait(duration)]
        case .showNotification:
            return [.showNotification(title: "TaskOS", message: "")]
        case .copyText:
            let literal = clause.copyText ?? ""
            guard !literal.isEmpty else { return [] }
            return [.copyText(literal)]
        default:
            return []
        }
    }

    private static func sameCase(_ lhs: ComposerActionDraft, _ rhs: ComposerActionDraft) -> Bool {
        switch (lhs, rhs) {
        case (.openApplication, .openApplication),
             (.hideApplication, .hideApplication),
             (.quitApplication, .quitApplication),
             (.openFile, .openFile),
             (.revealInFinder, .revealInFinder),
             (.openWebsite, .openWebsite),
             (.arrangeWindow, .arrangeWindow),
             (.wait, .wait),
             (.showNotification, .showNotification),
             (.copyText, .copyText):
            return true
        default:
            return false
        }
    }

    private static func matchesExactly(_ lhs: ComposerActionDraft, _ rhs: ComposerActionDraft) -> Bool {
        switch (lhs, rhs) {
        case (.openApplication(let a, _), .openApplication(let b, _)),
             (.hideApplication(let a, _), .hideApplication(let b, _)),
             (.quitApplication(let a, _), .quitApplication(let b, _)),
             (.arrangeWindow(let a, _, _, _), .arrangeWindow(let b, _, _, _)),
             (.openWebsite(let a, _), .openWebsite(let b, _)):
            return a.caseInsensitiveCompare(b) == .orderedSame
        default:
            return sameCase(lhs, rhs)
        }
    }

    private func merge(previous: ComposerActionDraft, new: ComposerActionDraft) -> ComposerActionDraft {
        switch (previous, new) {
        case (.openApplication(let oldName, let resolved), .openApplication(let newName, _)):
            if oldName.caseInsensitiveCompare(newName) == .orderedSame {
                return .openApplication(name: newName, resolved: resolved)
            }
            return new

        case (.hideApplication(let oldName, let resolved), .hideApplication(let newName, _)):
            if oldName.caseInsensitiveCompare(newName) == .orderedSame {
                return .hideApplication(name: newName, resolved: resolved)
            }
            return new

        case (.quitApplication(let oldName, let resolved), .quitApplication(let newName, _)):
            if oldName.caseInsensitiveCompare(newName) == .orderedSame {
                return .quitApplication(name: newName, resolved: resolved)
            }
            return new

        case (.openFile(let oldTarget), .openFile(let newTarget)):
            return .openFile(target: newTarget ?? oldTarget)

        case (.revealInFinder(let oldTarget), .revealInFinder(let newTarget)):
            return .revealInFinder(target: newTarget ?? oldTarget)

        case (.showNotification(let title, let message), .showNotification):
            return .showNotification(title: title, message: message)

        case (.openWebsite(let oldURL, let browser), .openWebsite(let newURL, _)):
            if oldURL.caseInsensitiveCompare(newURL) == .orderedSame {
                return .openWebsite(url: oldURL, browser: browser)
            }
            return new

        case (.arrangeWindow(let oldName, let resolved, let preset, let display), .arrangeWindow(let newName, _, _, _)):
            if oldName.caseInsensitiveCompare(newName) == .orderedSame {
                return .arrangeWindow(name: newName, resolved: resolved, preset: preset, display: display)
            }
            return new

        default:
            return new
        }
    }

    private func clauseText(_ clause: ParsedClause) -> String {
        text.substring(in: clause.span)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func trailingFragmentStart() -> Int {
        let tokens = CommandTokenizer.tokenize(text)
        var start = 0
        for token in tokens {
            switch token.kind {
            case .word(let word) where Self.language.shared.connectorWords.contains(word):
                start = token.span.end
            case .punctuation(let punctuation) where Self.language.shared.connectorPunctuation.contains(punctuation):
                start = token.span.end
            default:
                break
            }
        }
        return start
    }

    private static func render(_ element: ComposerElement) -> String {
        switch element {
        case .action(let action):
            return render(action.draft)
        case .unresolved(let value):
            return value
        }
    }

    private static func render(_ draft: ComposerActionDraft) -> String {
        switch draft {
        case .openApplication(let name, _):
            return language.canonicalActionTemplate(.openApplication)?
                .render(["application": language.applicationPhrase(name)]) ?? "Open \(name)"
        case .hideApplication(let name, _):
            return language.canonicalActionTemplate(.hideApplication)?
                .render(["application": language.applicationPhrase(name)]) ?? "Hide \(name)"
        case .quitApplication(let name, _):
            return language.canonicalActionTemplate(.quitApplication)?
                .render(["application": language.applicationPhrase(name)]) ?? "Quit \(name)"
        case .openFile(let target):
            let variant = target?.kind == .folder ? "folder" : "file"
            return language.canonicalActionTemplate(.openFile, variant: variant)?.render()
                ?? (target?.kind == .folder ? "Open the selected folder" : "Open the selected file")
        case .revealInFinder:
            return language.canonicalActionTemplate(.revealInFinder)?.render()
                ?? "Reveal the selected item"
        case .openWebsite(let url, _):
            return language.canonicalActionTemplate(.openWebsite)?
                .render(["url": url]) ?? "Open \(url)"
        case .arrangeWindow(let name, _, let preset, _):
            switch preset {
            case .maximize:
                return language.canonicalActionTemplate(.arrangeWindow, variant: "maximize")?
                    .render(["application": language.applicationPhrase(name)]) ?? "Maximize \(name)"
            case .center:
                return language.canonicalActionTemplate(.arrangeWindow, variant: "center")?
                    .render(["application": language.applicationPhrase(name)]) ?? "Center \(name)"
            default:
                return language.canonicalActionTemplate(.arrangeWindow)?
                    .render([
                        "application": language.applicationPhrase(name),
                        "preset": language.arrangePresetPhrase(preset),
                    ]) ?? "Put \(name) \(language.arrangePresetPhrase(preset))"
            }
        case .wait(let duration):
            return language.canonicalActionTemplate(.wait)?
                .render(["duration": CanonicalPhrase.durationText(duration)])
                ?? "Wait \(CanonicalPhrase.durationText(duration)) seconds"
        case .showNotification:
            return language.canonicalActionTemplate(.showNotification)?.render()
                ?? "Show a notification"
        case .copyText(let value):
            return language.copyTextPhrase(value)
        }
    }

    private static func render(_ trigger: ComposerTriggerDraft) -> String {
        switch trigger {
        case .manual:
            return ""
        case .daily(let hour, let minute):
            return language.scheduleTemplate("daily")?
                .render(["clock": clockText(hour: hour, minute: minute)])
                ?? "Every day at \(clockText(hour: hour, minute: minute))"
        case .weekdays(let days, let hour, let minute):
            let names = days.sorted { $0.rawValue < $1.rawValue }.map(\.displayName).joined(separator: ", ")
            return language.scheduleTemplate("weekdays")?
                .render(["days": names, "clock": clockText(hour: hour, minute: minute)])
                ?? "Every \(names) at \(clockText(hour: hour, minute: minute))"
        case .interval(let seconds):
            return language.scheduleTemplate("interval")?
                .render(["interval": intervalText(seconds)])
                ?? "Every \(intervalText(seconds))"
        case .relative(let seconds):
            return language.scheduleTemplate("relative")?
                .render(["interval": intervalText(seconds)])
                ?? "In \(intervalText(seconds))"
        case .once(let hour, let minute):
            return language.scheduleTemplate("once")?
                .render(["clock": clockText(hour: hour, minute: minute)])
                ?? "Once at \(clockText(hour: hour, minute: minute))"
        case .oneTime(let date):
            return language.scheduleTemplate("oneTime")?
                .render(["date": language.absoluteDateTimeText(date)])
                ?? "Once on \(language.absoluteDateTimeText(date))"
        case .applicationLifecycle(_, let label, let event):
            if label.isEmpty { return "" }
            return language.canonicalTriggerTemplate(.applicationLifecycle)?
                .render(["application": label, "event": event.displayName])
                ?? "When \(label) \(event.displayName)"
        case .wake:
            return language.canonicalTriggerTemplate(.wake)?.render() ?? "When the Mac wakes"
        case .displayConnection(let event, let selection):
            let noun = selection == .anyExternal ? "a display" : selection.displayName
            let variant = event == .connected ? "connected" : "disconnected"
            return language.canonicalTriggerTemplate(.displayConnection, variant: variant)?
                .render(["display": noun])
                ?? (event == .connected ? "When \(noun) connects" : "When \(noun) disconnects")
        case .externalVolume(let event, let selection):
            let noun = selection == .anyExternal ? "an external drive" : selection.displayName
            let variant = event == .mounted ? "mounted" : "unmounted"
            return language.canonicalTriggerTemplate(.externalVolume, variant: variant)?
                .render(["volume": noun])
                ?? (event == .mounted ? "When \(noun) mounts" : "When \(noun) unmounts")
        case .powerSource(let event):
            return language.canonicalTriggerTemplate(.powerSource)?
                .render(["event": event.displayName]) ?? "When the Mac \(event.displayName)"
        case .batteryThreshold(let comparator, let percentage):
            let direction = language.trigger.batteryDirectionWords[comparator]
                ?? (comparator == .below ? "drops below" : "rises above")
            return language.canonicalTriggerTemplate(.batteryThreshold)?
                .render(["direction": direction, "percentage": "\(percentage)"])
                ?? "When the battery \(direction) \(percentage)%"
        }
    }

    private static func clockText(hour: Int, minute: Int) -> String {
        language.clockText(hour: hour, minute: minute)
    }

    private static func intervalText(_ seconds: TimeInterval) -> String {
        language.intervalText(seconds)
    }

    private mutating func bumpRevision() {
        revision = revision.next()
    }

    private func currentSnapshot() -> Snapshot {
        Snapshot(
            text: text,
            trigger: trigger,
            elements: elements,
            parseOutcome: parseOutcome,
            diagnostics: diagnostics,
            revision: revision,
            resolution: resolution.value,
            rationaleText: rationaleText
        )
    }

    private mutating func recordHistory() {
        undoStack.append(currentSnapshot())
        if undoStack.count > Self.historyLimit {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    private mutating func restore(_ snapshot: Snapshot) {
        text = snapshot.text
        trigger = snapshot.trigger
        elements = snapshot.elements
        parseOutcome = snapshot.parseOutcome
        diagnostics = snapshot.diagnostics
        revision = snapshot.revision
        resolution.value = snapshot.resolution
        rationaleText = snapshot.rationaleText
    }
}
