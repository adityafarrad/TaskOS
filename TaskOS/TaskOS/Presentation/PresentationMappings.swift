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

    static func suggestedName(for draft: ComposerActionDraft) -> String {
        switch draft {
        case .openApplication(_, let resolved):
            return resolved.map { "Open \($0.label)" } ?? "Open Application"
        case .hideApplication(_, let resolved):
            return resolved.map { "Hide \($0.label)" } ?? "Hide Application"
        case .quitApplication(_, let resolved):
            return resolved.map { "Quit \($0.label)" } ?? "Quit Application"
        case .arrangeWindow(_, let resolved, _, _):
            return resolved.map { "Arrange \($0.label)" } ?? "Arrange Window"
        case .openWebsite(let url, _):
            if OpenWebsiteAction.isAbsoluteHTTPURL(url), let host = URL(string: url)?.host(), !host.isEmpty {
                return "Open \(host)"
            }
            return "Open Website"
        case .openFile(let target):
            return target.map { "Open \($0.displayName)" } ?? "Open File or Folder"
        case .revealInFinder(let target):
            return target.map { "Reveal \($0.displayName)" } ?? "Reveal in Finder"
        case .wait:
            return "Wait"
        case .showNotification(let title, _):
            return title.isEmpty ? "Notification" : title
        case .copyText(let value):
            return value.isEmpty ? "Copy Text" : "Copy \(value.prefix(40))"
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

    static func summary(for draft: ComposerActionDraft, fileStatus: (FileTarget) -> FileTargetStatus) -> String {
        switch draft {
        case .openApplication(_, let resolved):
            return resolved?.label ?? "Choose an app"
        case .hideApplication(_, let resolved):
            return resolved?.label ?? "Choose an app"
        case .quitApplication(_, let resolved):
            return resolved?.label ?? "Choose an app"
        case .openFile(let target):
            return fileSummary(target, fileStatus: fileStatus, prompt: "Choose a file or folder")
        case .revealInFinder(let target):
            return fileSummary(target, fileStatus: fileStatus, prompt: "Choose a file or folder")
        case .openWebsite(let url, let browser):
            guard OpenWebsiteAction.isAbsoluteHTTPURL(url) else { return "Add a web address" }
            let host = URL(string: url)?.host() ?? url
            if let browser {
                return "\(host) · \(browser.label)"
            }
            return host
        case .arrangeWindow(_, let resolved, let preset, _):
            let app = resolved?.label ?? "Choose an app"
            return "\(app) · \(preset.displayName)"
        case .wait(let duration):
            return String(format: "%.1f seconds", duration)
        case .showNotification(let title, _):
            return title.isEmpty ? "Notification" : title
        case .copyText(let value):
            return value.isEmpty ? "Enter text to copy" : value
        }
    }

    static func missingRequirement(
        for draft: ComposerActionDraft,
        fileStatus: (FileTarget) -> FileTargetStatus
    ) -> String? {
        switch draft {
        case .openApplication(_, let resolved),
             .hideApplication(_, let resolved),
             .quitApplication(_, let resolved),
             .arrangeWindow(_, let resolved, _, _):
            return resolved == nil ? "an app" : nil
        case .openFile(let target), .revealInFinder(let target):
            guard let target else { return "a file or folder" }
            switch fileStatus(target) {
            case .available:
                return nil
            case .moved:
                return "the file again — it moved"
            case .missing:
                return "the file again — it is missing"
            }
        case .openWebsite(let url, _):
            return OpenWebsiteAction.isAbsoluteHTTPURL(url) ? nil : "a full http:// or https:// address"
        case .copyText(let value):
            return value.isEmpty ? "text to copy" : nil
        case .wait, .showNotification:
            return nil
        }
    }

    private static func fileSummary(
        _ target: FileTarget?,
        fileStatus: (FileTarget) -> FileTargetStatus,
        prompt: String
    ) -> String {
        guard let target else { return prompt }
        switch fileStatus(target) {
        case .available:
            return target.displayName
        case .moved(let name):
            return "\(name) · moved"
        case .missing:
            return "\(target.displayName) · missing"
        }
    }

    static func isUnresolved(_ draft: ComposerActionDraft, fileStatus: (FileTarget) -> FileTargetStatus) -> Bool {
        switch draft {
        case .openApplication(_, let resolved),
             .hideApplication(_, let resolved),
             .quitApplication(_, let resolved),
             .arrangeWindow(_, let resolved, _, _):
            return resolved == nil
        case .openFile(let target), .revealInFinder(let target):
            guard let target else { return true }
            return fileStatus(target) != .available
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

    static func summary(for record: RunRecord) -> String {
        let total = record.actions.count
        let completed = record.actions.filter { $0.outcome.isSuccess }.count
        let stepWord = total == 1 ? "step" : "steps"

        switch record.status {
        case .running:
            return "Running…"
        case .succeeded:
            return total == 1 ? "The step completed." : "All \(total) steps completed."
        case .failed:
            if let failed = record.actions.first(where: { if case .failed = $0.outcome { return true } else { return false } }),
               case .failed(let failure) = failed.outcome {
                return "Completed \(completed) of \(total) \(stepWord). Step \(failed.index + 1) failed: \(failure.message)"
            }
            return "Failed after \(completed) of \(total) \(stepWord)."
        case .timedOut:
            return "Timed out after \(completed) of \(total) \(stepWord)."
        case .cancelled:
            return "Stopped after \(completed) of \(total) \(stepWord). Steps already completed are not undone."
        case .interrupted:
            return "Interrupted after \(completed) of \(total) \(stepWord). Steps already completed are not undone."
        }
    }

    static func permissionFix(for record: RunRecord) -> PermissionKind? {
        for item in record.actions {
            guard case .failed(let failure) = item.outcome else { continue }
            let message = failure.message.lowercased()
            if message.contains("notification permission") {
                return .notifications
            }
            if message.contains("accessibility") {
                return .accessibility
            }
        }
        return nil
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
