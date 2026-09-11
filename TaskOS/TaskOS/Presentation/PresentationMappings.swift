import SwiftUI
import TaskOSCore

enum ActionPresentation {
    static func title(for id: ActionID) -> String {
        switch id {
        case .openApplication: return "Open Application"
        case .hideApplication: return "Hide Application"
        case .quitApplication: return "Quit Application"
        case .openFile: return "Open File or Folder"
        case .revealInFinder: return "Reveal in Finder"
        case .openWebsite: return "Open Website"
        case .arrangeWindow: return "Arrange Window"
        case .wait: return "Wait"
        case .showNotification: return "Show Notification"
        case .copyText: return "Copy Text"
        }
    }

    static func title(for draft: ComposerActionDraft) -> String {
        title(for: draft.actionID)
    }

    static func shortTitle(for draft: ComposerActionDraft) -> String {
        switch draft {
        case .openApplication: return "Open App"
        case .hideApplication: return "Hide App"
        case .quitApplication: return "Quit App"
        case .openFile: return "Open File"
        case .revealInFinder: return "Reveal"
        case .openWebsite: return "Open Website"
        case .arrangeWindow: return "Arrange Window"
        case .wait: return "Wait"
        case .showNotification: return "Notify"
        case .copyText: return "Copy Text"
        }
    }

    static func symbol(for id: ActionID) -> String {
        switch id {
        case .openApplication: return "macwindow"
        case .hideApplication: return "eye.slash"
        case .quitApplication: return "xmark.circle"
        case .openFile: return "doc"
        case .revealInFinder: return "folder"
        case .openWebsite: return "globe"
        case .arrangeWindow: return "rectangle.split.2x1"
        case .wait: return "clock"
        case .showNotification: return "bell"
        case .copyText: return "doc.on.clipboard"
        }
    }

    static func symbol(for draft: ComposerActionDraft) -> String {
        symbol(for: draft.actionID)
    }

    static func tint(for id: ActionID) -> Color {
        switch id {
        case .openApplication, .hideApplication, .quitApplication: return .blue
        case .openFile, .revealInFinder: return .orange
        case .openWebsite: return .teal
        case .arrangeWindow: return .indigo
        case .wait: return .gray
        case .showNotification: return .pink
        case .copyText: return .purple
        }
    }

    static func tint(for draft: ComposerActionDraft) -> Color {
        tint(for: draft.actionID)
    }

    static func summary(for draft: ComposerActionDraft, missingFile: (FileTarget) -> Bool) -> String {
        switch draft {
        case .openApplication(_, let resolved):
            return resolved?.label ?? "Choose an application"
        case .hideApplication(_, let resolved):
            return resolved?.label ?? "Choose an application"
        case .quitApplication(_, let resolved):
            return resolved?.label ?? "Choose an application"
        case .openFile(let target):
            guard let target else { return "Choose a file or folder" }
            return missingFile(target) ? "\(target.displayName) · moved or deleted" : target.displayName
        case .revealInFinder(let target):
            guard let target else { return "Choose a file or folder" }
            return missingFile(target) ? "\(target.displayName) · moved or deleted" : target.displayName
        case .openWebsite(let url, let browser):
            let host = URL(string: url)?.host() ?? url
            if let browser {
                return "\(host) · \(browser.label)"
            }
            return host.isEmpty ? "Enter a web address" : host
        case .arrangeWindow(_, let resolved, let preset, _):
            let app = resolved?.label ?? "Choose an application"
            return "\(app) · \(preset.displayName)"
        case .wait(let duration):
            return String(format: "%.1f seconds", duration)
        case .showNotification(let title, _):
            return title.isEmpty ? "Notification" : title
        case .copyText(let value):
            return value.isEmpty ? "Enter text to copy" : value
        }
    }

    static func isUnresolved(_ draft: ComposerActionDraft, missingFile: (FileTarget) -> Bool) -> Bool {
        switch draft {
        case .openApplication(_, let resolved),
             .hideApplication(_, let resolved),
             .quitApplication(_, let resolved),
             .arrangeWindow(_, let resolved, _, _):
            return resolved == nil
        case .openFile(let target), .revealInFinder(let target):
            return target == nil
        case .openWebsite(let url, _):
            return !OpenWebsiteAction.isAbsoluteHTTPURL(url)
        case .copyText(let value):
            return value.isEmpty
        case .wait, .showNotification:
            return false
        }
    }
}

enum TriggerPresentation {
    static func title(for family: ComposerViewModel.TriggerFamily) -> String {
        switch family {
        case .manual: return "Manual"
        case .schedule: return "Schedule"
        case .applicationLifecycle: return "App Event"
        case .wake: return "Mac Wakes"
        case .displayConnection: return "Display"
        case .externalVolume: return "External Drive"
        case .powerSource: return "Power Source"
        case .batteryThreshold: return "Battery"
        }
    }

    static func symbol(for family: ComposerViewModel.TriggerFamily) -> String {
        switch family {
        case .manual: return "hand.tap"
        case .schedule: return "calendar"
        case .applicationLifecycle: return "arrow.up.forward.app"
        case .wake: return "sunrise"
        case .displayConnection: return "display"
        case .externalVolume: return "externaldrive"
        case .powerSource: return "bolt"
        case .batteryThreshold: return "battery.50"
        }
    }
}

enum RunPresentation {
    static func title(for status: RunStatus) -> String {
        switch status {
        case .running: return "Running"
        case .succeeded: return "Succeeded"
        case .failed: return "Failed"
        case .timedOut: return "Timed out"
        case .cancelled: return "Cancelled"
        case .interrupted: return "Interrupted"
        }
    }

    static func symbol(for status: RunStatus) -> String {
        switch status {
        case .running: return "arrow.triangle.2.circlepath"
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        case .timedOut: return "clock.badge.exclamationmark"
        case .cancelled: return "slash.circle"
        case .interrupted: return "exclamationmark.triangle.fill"
        }
    }

    static func tint(for status: RunStatus) -> Color {
        switch status {
        case .running: return .blue
        case .succeeded: return .green
        case .failed: return .red
        case .timedOut: return .orange
        case .cancelled: return .gray
        case .interrupted: return .orange
        }
    }

    static func symbol(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        case .cancelled: return "slash.circle"
        case .notExecuted: return "circle.dashed"
        }
    }

    static func tint(for outcome: ActionOutcome) -> Color {
        switch outcome {
        case .succeeded: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .notExecuted: return .gray
        }
    }

    static func detail(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "Done"
        case .failed(let failure): return failure.message
        case .cancelled: return "Cancelled"
        case .notExecuted: return "Not executed"
        }
    }
}

enum TemplatePresentation {
    static func symbol(for id: String) -> String {
        switch id {
        case "workday": return "briefcase"
        case "study": return "book"
        case "research": return "safari"
        case "writing": return "square.and.pencil"
        case "meeting": return "person.2"
        case "weekday": return "calendar.badge.clock"
        case "break": return "cup.and.saucer"
        case "external-display": return "display"
        case "return-main": return "rectangle.on.rectangle"
        case "drive-folder": return "externaldrive"
        case "battery": return "battery.50"
        case "agenda": return "doc.on.clipboard"
        default: return "square.grid.2x2"
        }
    }

    static func featured(_ templates: [AutomationTemplate]) -> [AutomationTemplate] {
        let preferred = ["workday", "study", "writing", "break", "external-display", "agenda"]
        let ordered = preferred.compactMap { id in templates.first { $0.id == id } }
        let remaining = templates.filter { template in !preferred.contains(template.id) }
        return ordered + remaining
    }
}

enum SidebarPresentation {
    static func symbol(for destination: SidebarDestination) -> String {
        switch destination {
        case .workflows: return "square.stack.3d.up"
        case .templates: return "square.grid.2x2"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}
