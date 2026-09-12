import SwiftUI
import TaskOSCore

struct WorkflowStatusPresentation: Equatable {
    var label: String
    var detail: String?
    var tint: Color
    var symbol: String
    var isAutomatic: Bool
    var isEnabled: Bool

    static func make(
        for workflow: SavedWorkflow,
        needsAttention: Bool,
        paused: Bool,
        nextRun: Date?
    ) -> WorkflowStatusPresentation {
        let trigger = workflow.definition.trigger
        let isSchedule = trigger.schedule != nil
        let isEvent = trigger.isEventTrigger
        let isAutomatic = isSchedule || isEvent
        let enabled = workflow.isEnabled

        let label: String
        if isSchedule {
            label = enabled ? "Schedule · On" : "Schedule · Off"
        } else if isEvent {
            label = enabled ? "Event · On" : "Event · Off"
        } else {
            label = "Manual · Ready to run"
        }

        var detail: String?
        if isAutomatic, enabled {
            if paused {
                detail = "Paused — won't run until resumed"
            } else if isSchedule {
                if let nextRun {
                    detail = "Next: \(nextRun.formatted(date: .abbreviated, time: .shortened))"
                } else {
                    detail = "No upcoming run"
                }
            } else {
                detail = "Runs when its event occurs"
            }
        }

        let tint: Color
        if needsAttention {
            tint = .orange
        } else if isAutomatic, enabled {
            tint = .green
        } else {
            tint = .secondary
        }

        return WorkflowStatusPresentation(
            label: label,
            detail: detail,
            tint: tint,
            symbol: isSchedule ? "calendar" : (isEvent ? "bolt" : "hand.tap"),
            isAutomatic: isAutomatic,
            isEnabled: enabled
        )
    }
}

enum EditorLifecycleState: Equatable {
    case empty
    case draft
    case unsaved
    case savedManual
    case savedAutomatic(enabled: Bool, paused: Bool)

    var label: String {
        switch self {
        case .empty:
            return "New workflow"
        case .draft:
            return "Draft · not saved yet"
        case .unsaved:
            return "Unsaved changes"
        case .savedManual:
            return "Saved · Ready to run"
        case .savedAutomatic(let enabled, let paused):
            if !enabled { return "Saved · Off" }
            return paused ? "Saved · On · Paused" : "Saved · On"
        }
    }

    var symbol: String {
        switch self {
        case .empty:
            return "circle.dashed"
        case .draft, .unsaved:
            return "pencil.circle.fill"
        case .savedManual, .savedAutomatic:
            return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .empty:
            return .secondary
        case .draft, .unsaved:
            return .orange
        case .savedManual, .savedAutomatic:
            return .green
        }
    }

    var hasUnsavedEdits: Bool {
        switch self {
        case .draft, .unsaved:
            return true
        default:
            return false
        }
    }
}
