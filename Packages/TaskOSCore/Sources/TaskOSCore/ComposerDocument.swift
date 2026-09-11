import Foundation

public enum ComposerActionDraft: Hashable, Sendable {
    case openApplication(name: String, resolved: ResourceReference?)
    case openWebsite(url: String, browser: ResourceReference?)
    case arrangeWindow(name: String, resolved: ResourceReference?, preset: WindowPreset, display: WindowDisplaySelection)
    case wait(TimeInterval)
    case showNotification(title: String, message: String)
}

public enum ComposerTriggerDraft: Hashable, Sendable {
    case manual
    case daily(hour: Int, minute: Int)
    case weekdays(Set<Weekday>, hour: Int, minute: Int)
    case interval(TimeInterval)
    case relative(TimeInterval)
    case once(hour: Int, minute: Int)
    case oneTime(Date)
}

public struct ComposerAction: Hashable, Sendable, Identifiable {
    public let id: UUID
    public let draft: ComposerActionDraft

    public init(id: UUID = UUID(), draft: ComposerActionDraft) {
        self.id = id
        self.draft = draft
    }
}

public enum ComposerElement: Hashable, Sendable {
    case action(ComposerAction)
    case unresolved(String)
}

public struct ComposerDocument: Sendable {
    private struct Snapshot: Sendable {
        let text: String
        let trigger: ComposerTriggerDraft
        let elements: [ComposerElement]
        let parseOutcome: ParseOutcome
        let diagnostics: [ParseDiagnostic]
        let revision: WorkflowRevision
    }

    private let parser = CommandParser()
    private static let historyLimit = 100

    public private(set) var text: String
    public private(set) var trigger: ComposerTriggerDraft
    public private(set) var elements: [ComposerElement]
    public private(set) var parseOutcome: ParseOutcome
    public private(set) var diagnostics: [ParseDiagnostic]
    public private(set) var revision: WorkflowRevision

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []

    public init(text: String = "") {
        self.text = text
        self.trigger = .manual
        self.elements = []
        self.parseOutcome = .needsInput
        self.diagnostics = []
        self.revision = WorkflowRevision(1)
        applyText(text)
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

    public var hasUnresolvedActions: Bool {
        hasUnresolvedApplications || hasUnresolvedWebsites
    }

    public mutating func setText(_ newText: String) {
        guard newText != text else { return }
        recordHistory()
        applyText(newText)
        bumpRevision()
    }

    public mutating func accept(_ suggestion: Suggestion) {
        let start = trailingFragmentStart()
        var prefix = String(text.prefix(start))
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

    public mutating func resolveApplication(id: UUID, reference: ResourceReference) {
        guard let action = action(id: id) else { return }
        switch action.draft {
        case .openApplication(let name, _):
            updateAction(id: id, draft: .openApplication(name: name, resolved: reference))
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
        let actionText = elements.map(Self.render).joined(separator: ", then ")
        let triggerText = Self.render(trigger)
        if triggerText.isEmpty {
            return actionText
        }
        if actionText.isEmpty {
            return triggerText
        }
        return triggerText + ", then " + actionText
    }

    public func resolvedActions() -> [ActionConfiguration]? {
        var result: [ActionConfiguration] = []
        for element in elements {
            guard case .action(let action) = element else { continue }
            switch action.draft {
            case .openApplication(_, let resolved):
                guard let resolved else { return nil }
                result.append(.openApplication(OpenApplicationAction(application: resolved)))
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
            }
        }
        return result
    }

    public func makeDefinition(
        name: String,
        id: AutomationID = AutomationID(),
        revision: WorkflowRevision = WorkflowRevision(1),
        now: Date = Date()
    ) -> AutomationDefinition? {
        guard !hasUnresolvedText else { return nil }
        guard let actions = resolvedActions(), !actions.isEmpty else { return nil }
        guard let triggerConfiguration = triggerConfiguration(relativeTo: now) else { return nil }
        let definition = AutomationDefinition(
            id: id,
            name: name,
            revision: revision,
            trigger: triggerConfiguration,
            actions: actions
        )
        return definition.validate(relativeTo: now).isValid ? definition : nil
    }

    public func triggerConfiguration(relativeTo now: Date = Date()) -> TriggerConfiguration? {
        switch trigger {
        case .manual:
            return .manual(ManualTrigger())
        case .daily(let hour, let minute):
            return .schedule(.daily(hour: hour, minute: minute))
        case .weekdays(let days, let hour, let minute):
            return .schedule(.weekdays(days, hour: hour, minute: minute))
        case .interval(let seconds):
            return .schedule(.interval(every: seconds, startingAt: now))
        case .relative(let seconds):
            return .schedule(.oneTime(now.addingTimeInterval(seconds)))
        case .once(let hour, let minute):
            let calendar = Calendar.current
            let components = DateComponents(hour: hour, minute: minute, second: 0)
            guard let date = calendar.nextDate(
                after: now.addingTimeInterval(-1),
                matching: components,
                matchingPolicy: .nextTime,
                repeatedTimePolicy: .first,
                direction: .forward
            ) else {
                return nil
            }
            return .schedule(.oneTime(date))
        case .oneTime(let date):
            return .schedule(.oneTime(date))
        }
    }

    public mutating func setTrigger(_ draft: ComposerTriggerDraft) {
        guard draft != trigger else { return }
        recordHistory()
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
        let parsed = parser.parse(newText)
        parseOutcome = parsed.outcome
        diagnostics = parsed.diagnostics
        reconcileElements(from: parsed)
    }

    private mutating func reconcileElements(from parsed: ParsedCommand) {
        let previousActions = actions
        var cursor = 0
        var newElements: [ComposerElement] = []
        var newTrigger: ComposerTriggerDraft = .manual

        for clause in parsed.clauses {
            switch clause.kind {
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
                case .incomplete, .none:
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .openApplication:
                for name in clause.resourceNames {
                    let draft: ComposerActionDraft
                    if ResourceNameHeuristics.isWebsite(name) {
                        draft = .openWebsite(url: ResourceNameHeuristics.normalizedWebsiteURL(name), browser: nil)
                    } else {
                        draft = .openApplication(name: name, resolved: nil)
                    }
                    newElements.append(.action(reusedAction(for: draft, from: previousActions, cursor: &cursor)))
                }

            case .arrangeWindow:
                let name = (clause.arrangeApplicationName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if let preset = clause.arrangePreset, !name.isEmpty {
                    let draft = ComposerActionDraft.arrangeWindow(
                        name: name,
                        resolved: nil,
                        preset: preset,
                        display: .current
                    )
                    newElements.append(.action(reusedAction(for: draft, from: previousActions, cursor: &cursor)))
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .wait:
                if let duration = clause.duration, WaitAction.allowedRange.contains(duration) {
                    newElements.append(.action(reusedAction(for: .wait(duration), from: previousActions, cursor: &cursor)))
                } else {
                    newElements.append(.unresolved(clauseText(clause)))
                }

            case .showNotification:
                newElements.append(
                    .action(
                        reusedAction(
                            for: .showNotification(title: "TaskOS", message: ""),
                            from: previousActions,
                            cursor: &cursor
                        )
                    )
                )

            case .unsupported, .unrecognized:
                newElements.append(.unresolved(clauseText(clause)))
            }
        }

        elements = newElements
        trigger = newTrigger
    }

    private func reusedAction(
        for draft: ComposerActionDraft,
        from previous: [ComposerAction],
        cursor: inout Int
    ) -> ComposerAction {
        guard cursor < previous.count else {
            return ComposerAction(draft: draft)
        }
        let previousAction = previous[cursor]
        cursor += 1
        return ComposerAction(id: previousAction.id, draft: merge(previous: previousAction.draft, new: draft))
    }

    private func merge(previous: ComposerActionDraft, new: ComposerActionDraft) -> ComposerActionDraft {
        switch (previous, new) {
        case (.openApplication(let oldName, let resolved), .openApplication(let newName, _)):
            if oldName.caseInsensitiveCompare(newName) == .orderedSame {
                return .openApplication(name: newName, resolved: resolved)
            }
            return new

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
            case .word(let word) where word == "and" || word == "then" || word == "also":
                start = token.span.end
            case .punctuation(let punctuation) where punctuation == ",":
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
            return "Open \(name)"
        case .openWebsite(let url, _):
            return "Open \(url)"
        case .arrangeWindow(let name, _, let preset, _):
            switch preset {
            case .maximize:
                return "Maximize \(name)"
            case .center:
                return "Center \(name)"
            default:
                return "Put \(name) \(preset.phraseSuffix)"
            }
        case .wait(let duration):
            return "Wait \(CanonicalPhrase.durationText(duration)) seconds"
        case .showNotification:
            return "Show a notification"
        }
    }

    private static func render(_ trigger: ComposerTriggerDraft) -> String {
        switch trigger {
        case .manual:
            return ""
        case .daily(let hour, let minute):
            return "Every day at \(clockText(hour: hour, minute: minute))"
        case .weekdays(let days, let hour, let minute):
            let names = days.sorted { $0.rawValue < $1.rawValue }.map(\.displayName).joined(separator: ", ")
            return "Every \(names) at \(clockText(hour: hour, minute: minute))"
        case .interval(let seconds):
            return "Every \(intervalText(seconds))"
        case .relative(let seconds):
            return "In \(intervalText(seconds))"
        case .once(let hour, let minute):
            return "Once at \(clockText(hour: hour, minute: minute))"
        case .oneTime(let date):
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            return "Once at \(clockText(hour: components.hour ?? 0, minute: components.minute ?? 0))"
        }
    }

    private static func clockText(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        var display = hour % 12
        if display == 0 { display = 12 }
        return String(format: "%d:%02d %@", display, minute, period)
    }

    private static func intervalText(_ seconds: TimeInterval) -> String {
        let minutes = seconds / 60
        if minutes >= 60, minutes.truncatingRemainder(dividingBy: 60) == 0 {
            let hours = Int(minutes / 60)
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        let whole = Int(minutes)
        return whole == 1 ? "1 minute" : "\(whole) minutes"
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
            revision: revision
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
    }
}
