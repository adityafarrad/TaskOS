import SwiftUI
import TaskOSCore

struct StepConfigurationView: View {
    let action: ComposerAction
    let model: ComposerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.md) {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch action.draft {
        case .openApplication(let name, let resolved):
            applicationRow(label: resolved?.label, missing: "Unresolved: \(name)")

        case .hideApplication(let hideName, let hideResolved),
             .quitApplication(let hideName, let hideResolved):
            applicationRow(label: hideResolved?.label, missing: "Unresolved: \(hideName)")

        case .openFile(let fileTarget), .revealInFinder(let fileTarget):
            fileRow(target: fileTarget)

        case .openWebsite(let websiteURL, let websiteBrowser):
            VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
                TaskOSInspectorField(title: "Address") {
                    TextField(
                        "https://example.com",
                        text: Binding(
                            get: { websiteURL },
                            set: { model.updateWebsiteURL(id: action.id, url: $0) }
                        )
                    )
                }
                TaskOSInspectorField(title: "Browser") {
                    Picker("Browser", selection: websiteBrowserSelection) {
                        Text("Default browser").tag("")
                        ForEach(model.applications, id: \.bundleIdentifier) { application in
                            Text(application.displayName).tag(application.bundleIdentifier)
                        }
                    }
                    .labelsHidden()
                }
                Text(websiteBrowser.map { "Opens in \($0.label)" } ?? "Opens in your default browser")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !OpenWebsiteAction.isAbsoluteHTTPURL(websiteURL) {
                    Label("Enter an absolute http or https address.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

        case .arrangeWindow(let arrangementName, let arrangementResolved, let preset, let display):
            VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
                applicationRow(
                    label: arrangementResolved?.label,
                    missing: arrangementName.isEmpty ? "Choose an application" : "Unresolved: \(arrangementName)"
                )

                TaskOSInspectorField(title: "Position") {
                    Picker("Position", selection: presetBinding(for: preset)) {
                        ForEach(WindowPreset.allCases, id: \.self) { value in
                            Text(value.displayName).tag(value)
                        }
                    }
                    .labelsHidden()
                }

                TaskOSInspectorField(title: "Display") {
                    Picker("Display", selection: displayBinding(for: display)) {
                        Text("This window's display").tag(WindowDisplaySelection.current)
                        Text("Main display").tag(WindowDisplaySelection.main)
                        ForEach(model.displays, id: \.identifier) { screen in
                            Text(screen.isMain ? "\(screen.displayName) (main)" : screen.displayName)
                                .tag(WindowDisplaySelection.display(identifier: screen.identifier))
                        }
                    }
                    .labelsHidden()
                }
            }

        case .wait(let duration):
            VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text(String(format: "%.1f s", duration))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { duration },
                        set: { model.updateWait(id: action.id, duration: $0) }
                    ),
                    in: 0.1...30,
                    step: 0.1
                )
            }

        case .showNotification(let notificationTitle, let message):
            VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                TextField(
                    "Title",
                    text: Binding(
                        get: { notificationTitle },
                        set: { model.updateNotification(id: action.id, title: $0, message: message) }
                    )
                )
                TextField(
                    "Message",
                    text: Binding(
                        get: { message },
                        set: { model.updateNotification(id: action.id, title: notificationTitle, message: $0) }
                    )
                )
            }

        case .copyText(let value):
            VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                TextField(
                    "Text to copy",
                    text: Binding(
                        get: { value },
                        set: { model.updateCopyText(id: action.id, text: $0) }
                    )
                )
                Label("Replaces the clipboard contents.", systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func applicationRow(label: String?, missing: String) -> some View {
        TaskOSInspectorField(title: "Application") {
            VStack(alignment: .leading, spacing: TaskOSSpacing.xxs) {
                Picker("Application", selection: applicationSelection) {
                    Text("Select…").tag("")
                    ForEach(model.applications, id: \.bundleIdentifier) { application in
                        Text(application.displayName).tag(application.bundleIdentifier)
                    }
                }
                .labelsHidden()

                if let label {
                    Label(label, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label(missing, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    @ViewBuilder
    private func fileRow(target: FileTarget?) -> some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            if let target {
                Label(target.displayName, systemImage: target.kind == .folder ? "folder" : "doc")
                switch model.fileStatus(target) {
                case .available:
                    EmptyView()
                case .moved(let name):
                    Label("Moved to \(name). Choose it again to update the shortcut.", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                        .foregroundStyle(.orange)
                case .missing:
                    Label("This item is missing. Choose it again.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Label("Choose a file or folder", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            Button("Choose…") { model.chooseFile(id: action.id) }
        }
    }

    private var applicationSelection: Binding<String> {
        Binding(
            get: {
                switch action.draft {
                case .openApplication(_, let resolved):
                    return resolved?.identifier ?? ""
                case .hideApplication(_, let resolved):
                    return resolved?.identifier ?? ""
                case .quitApplication(_, let resolved):
                    return resolved?.identifier ?? ""
                case .arrangeWindow(_, let resolved, _, _):
                    return resolved?.identifier ?? ""
                default:
                    return ""
                }
            },
            set: { newValue in
                guard let application = model.applications.first(where: { $0.bundleIdentifier == newValue }) else {
                    return
                }
                model.resolve(id: action.id, application: application)
            }
        )
    }

    private var websiteBrowserSelection: Binding<String> {
        Binding(
            get: {
                if case .openWebsite(_, let browser) = action.draft {
                    return browser?.identifier ?? ""
                }
                return ""
            },
            set: { newValue in
                if newValue.isEmpty {
                    model.updateWebsiteBrowser(id: action.id, browser: nil)
                } else if let application = model.applications.first(where: { $0.bundleIdentifier == newValue }) {
                    model.updateWebsiteBrowser(
                        id: action.id,
                        browser: .application(bundleIdentifier: application.bundleIdentifier, label: application.displayName)
                    )
                }
            }
        )
    }

    private func presetBinding(for preset: WindowPreset) -> Binding<WindowPreset> {
        Binding(
            get: { preset },
            set: { model.updateArrangePreset(id: action.id, preset: $0) }
        )
    }

    private func displayBinding(for display: WindowDisplaySelection) -> Binding<WindowDisplaySelection> {
        Binding(
            get: { display },
            set: { model.updateArrangeDisplay(id: action.id, display: $0) }
        )
    }
}
