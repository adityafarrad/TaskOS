import Observation
import SwiftUI
import TaskOSCore

enum SidebarDestination: String, CaseIterable, Hashable, Identifiable {
    case workflows
    case templates
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workflows: return "Workflows"
        case .templates: return "Templates"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }
}

enum SidebarSelection: Hashable {
    case destination(SidebarDestination)
    case workflow(AutomationID)
}

@MainActor
@Observable
final class EditorSelection {
    var selectedStepID: UUID?
    var isTriggerSelected = false
    var isInspectorPresented = false

    var hasSelection: Bool {
        selectedStepID != nil || isTriggerSelected
    }

    func selectTrigger() {
        selectedStepID = nil
        isTriggerSelected = true
        isInspectorPresented = true
    }

    func selectStep(_ id: UUID) {
        selectedStepID = id
        isTriggerSelected = false
        isInspectorPresented = true
    }

    func clear() {
        selectedStepID = nil
        isTriggerSelected = false
    }

    func stepWasRemoved(_ id: UUID) {
        if selectedStepID == id {
            clear()
        }
    }
}

struct TaskOSCommandActions {
    var newWorkflow: () -> Void
    var focusComposer: () -> Void
    var run: () -> Void
    var cancelRun: () -> Void
    var save: () -> Void
    var undo: () -> Void
    var redo: () -> Void
    var openSettings: () -> Void
    var browseCapabilities: () -> Void
}

private struct TaskOSCommandActionsKey: FocusedValueKey {
    typealias Value = TaskOSCommandActions
}

extension FocusedValues {
    var taskOS: TaskOSCommandActions? {
        get { self[TaskOSCommandActionsKey.self] }
        set { self[TaskOSCommandActionsKey.self] = newValue }
    }
}

struct TaskOSCommands: Commands {
    @FocusedValue(\.taskOS) private var actions

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Workflow") { actions?.newWorkflow() }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(actions == nil)
        }

        CommandGroup(replacing: .undoRedo) {
            Button("Undo") { actions?.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(actions == nil)
            Button("Redo") { actions?.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(actions == nil)
        }

        CommandGroup(after: .saveItem) {
            Button("Save Workflow") { actions?.save() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(actions == nil)
            Button("Run Workflow") { actions?.run() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(actions == nil)
            Button("Cancel Run") { actions?.cancelRun() }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(actions == nil)
            Divider()
            Button("Find in Composer") { actions?.focusComposer() }
                .keyboardShortcut("k", modifiers: .command)
                .disabled(actions == nil)
            Button("Settings…") { actions?.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
                .disabled(actions == nil)
        }

        CommandGroup(replacing: .help) {
            Button("Supported Actions & Triggers") { actions?.browseCapabilities() }
                .keyboardShortcut("/", modifiers: .command)
                .disabled(actions == nil)
        }
    }
}
