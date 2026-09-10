import SwiftUI
import TaskOSCore

struct ContentView: View {
    @State private var model = ComposerViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                nameField
                commandField
                suggestionsSection
                unresolvedNotice
                stepsSection
                addMenu
                reviewSection
                librarySection
                historySection
                resultSection
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 660, alignment: .topLeading)
        .onAppear { model.loadApplicationsIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(TaskOSInfo.displayName)
                .font(.title2)
            Text("Type what you want your Mac to do, then review and test it.")
                .foregroundStyle(.secondary)
        }
    }

    private var nameField: some View {
        TextField(
            "Workflow name",
            text: Binding(get: { model.draftName }, set: { model.updateName($0) })
        )
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 320)
    }

    private var commandField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(
                "Start typing, for example: open Safari and wait 2 seconds",
                text: Binding(get: { model.text }, set: { model.setText($0) }),
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...4)

            HStack(spacing: 8) {
                Button("Undo") { model.undo() }
                    .disabled(!model.canUndo)
                Button("Redo") { model.redo() }
                    .disabled(!model.canRedo)
            }
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if !model.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("Suggestions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(model.suggestions, id: \.id) { suggestion in
                    Button {
                        model.accept(suggestion)
                    } label: {
                        HStack {
                            Text(suggestion.title)
                            Spacer()
                            if suggestion.requiresParameter {
                                Text("needs input")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Text(suggestion.category.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.08)))
        }
    }

    @ViewBuilder
    private var unresolvedNotice: some View {
        if !model.unresolvedTexts.isEmpty {
            Label(
                "Unresolved: \(model.unresolvedTexts.joined(separator: " / "))",
                systemImage: "exclamationmark.triangle"
            )
            .font(.callout)
            .foregroundStyle(.orange)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.headline)

            if model.actions.isEmpty {
                Text("No steps yet. Type a command or add an action.")
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(model.actions.enumerated()), id: \.element.id) { index, action in
                ActionCard(index: index, action: action, model: model)
            }
        }
    }

    private var addMenu: some View {
        Menu("Add action") {
            Button("Open a website") { model.add(.openWebsite(url: "https://", browser: nil)) }
            Button("Arrange a window") {
                model.add(.arrangeWindow(name: "", resolved: nil, preset: .leftHalf, display: .current))
            }
            Button("Wait 1 second") { model.add(.wait(1)) }
            Button("Wait 5 seconds") { model.add(.wait(5)) }
            Button("Show a notification") {
                model.add(.showNotification(title: "TaskOS", message: ""))
            }
        }
        .frame(maxWidth: 160)
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button(model.isBusy ? "Previewing..." : "Preview") { model.prepare() }
                    .disabled(!model.canPrepare || model.isBusy)

                Button("Save") { model.save() }
                    .disabled(!model.canPrepare)

                Button("Test now") { model.test() }
                    .disabled(!model.canTest)

                if let preview = model.preview, preview.requiredPermissions.contains(.accessibility) {
                    Button("Grant Accessibility") { model.requestAccessibilityPermission() }
                }

                Text("Test runs for real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notice = model.notice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let preview = model.preview {
                PreviewBox(preview: preview)
            }
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library")
                .font(.headline)

            if let error = model.libraryError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if model.savedWorkflows.isEmpty {
                Text("No saved workflows yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(model.savedWorkflows) { workflow in
                HStack(spacing: 12) {
                    Text(workflow.name)
                    Text(workflow.definition.actions.count == 1 ? "1 step" : "\(workflow.definition.actions.count) steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(workflow.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Edit") { model.loadForEditing(workflow) }
                    Button("Run") { model.runSaved(workflow) }
                    Button { model.deleteSaved(workflow) } label: { Image(systemName: "trash") }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)

            if model.history.isEmpty {
                Text("No runs yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(model.history.prefix(10).enumerated()), id: \.offset) { _, run in
                HStack(spacing: 12) {
                    Text(run.automationName)
                    Text(run.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(runStatusColor(run.status))
                    Spacer()
                    Text("\(run.actions.count) steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(run.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func runStatusColor(_ status: RunStatus) -> Color {
        switch status {
        case .succeeded: return .green
        case .failed: return .red
        case .timedOut: return .orange
        case .cancelled: return .gray
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        switch model.stage {
        case .running:
            ProgressView()
        case .finished(let record):
            GroupBox("Run result") {
                RunResultView(record: record)
            }
        default:
            EmptyView()
        }
    }
}

private struct ActionCard: View {
    let index: Int
    let action: ComposerAction
    let model: ComposerViewModel

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(index + 1).")
                        .monospacedDigit()
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Button { model.moveUp(id: action.id) } label: { Image(systemName: "arrow.up") }
                        .disabled(index == 0)
                    Button { model.moveDown(id: action.id) } label: { Image(systemName: "arrow.down") }
                    Button { model.remove(id: action.id) } label: { Image(systemName: "trash") }
                }

                detail
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: String {
        switch action.draft {
        case .openApplication: return "Open Application"
        case .openWebsite: return "Open Website"
        case .arrangeWindow: return "Arrange Window"
        case .wait: return "Wait"
        case .showNotification: return "Show Notification"
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch action.draft {
        case .openApplication(let name, let resolved):
            HStack(spacing: 8) {
                if let resolved {
                    Label(resolved.label, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Unresolved: \(name)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
                Spacer()
                Picker("Application", selection: applicationSelection) {
                    Text("Select...").tag("")
                    ForEach(model.applications, id: \.bundleIdentifier) { application in
                        Text(application.displayName).tag(application.bundleIdentifier)
                    }
                }
                .labelsHidden()
                .frame(width: 220)
            }

        case .openWebsite(let websiteURL, let websiteBrowser):
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    TextField(
                        "https://example.com",
                        text: Binding(
                            get: { websiteURL },
                            set: { model.updateWebsiteURL(id: action.id, url: $0) }
                        )
                    )
                    Picker("Browser", selection: websiteBrowserSelection) {
                        Text("Default browser").tag("")
                        ForEach(model.applications, id: \.bundleIdentifier) { application in
                            Text(application.displayName).tag(application.bundleIdentifier)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let arrangementResolved {
                        Label(arrangementResolved.label, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label(
                            arrangementName.isEmpty ? "Choose an application" : "Unresolved: \(arrangementName)",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }
                    Spacer()
                    Picker("Application", selection: applicationSelection) {
                        Text("Select...").tag("")
                        ForEach(model.applications, id: \.bundleIdentifier) { application in
                            Text(application.displayName).tag(application.bundleIdentifier)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)
                }

                HStack(spacing: 8) {
                    Picker("Position", selection: presetBinding(for: preset)) {
                        ForEach(WindowPreset.allCases, id: \.self) { value in
                            Text(value.displayName).tag(value)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)

                    Picker("Display", selection: displayBinding(for: display)) {
                        Text("This window's display").tag(WindowDisplaySelection.current)
                        Text("Main display").tag(WindowDisplaySelection.main)
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }
            }

        case .wait(let duration):
            HStack(spacing: 8) {
                Text("Duration")
                Slider(
                    value: Binding(
                        get: { duration },
                        set: { model.updateWait(id: action.id, duration: $0) }
                    ),
                    in: 0.1...30,
                    step: 0.1
                )
                Text(String(format: "%.1fs", duration))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

        case .showNotification(let notificationTitle, let message):
            VStack(alignment: .leading, spacing: 4) {
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
        }
    }

    private var applicationSelection: Binding<String> {
        Binding(
            get: {
                switch action.draft {
                case .openApplication(_, let resolved):
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

private struct PreviewBox: View {
    let preview: WorkflowPreview

    var body: some View {
        GroupBox("Preview") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(preview.isRunnable ? "Ready to test" : "Needs attention")
                        .font(.headline)
                        .foregroundStyle(preview.isRunnable ? Color.green : Color.orange)
                    Spacer()
                    Text("Revision \(preview.revision.value)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("When: \(preview.triggerTitle)")

                ForEach(preview.actions, id: \.index) { action in
                    HStack(spacing: 8) {
                        Image(systemName: symbol(for: action.status))
                            .foregroundStyle(color(for: action.status))
                        Text("\(action.index + 1). \(action.title)")
                        if let target = action.targetLabel {
                            Text("(\(target))").foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let detail = action.detail {
                            Text(detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                if !preview.requiredPermissions.isEmpty {
                    Text("Permissions: \(permissionList)")
                        .font(.caption)
                }

                ForEach(Array(preview.issues.enumerated()), id: \.offset) { _, issue in
                    Label(
                        issue.message,
                        systemImage: issue.severity == .error ? "exclamationmark.triangle" : "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(issue.severity == .error ? Color.red : Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var permissionList: String {
        preview.requiredPermissions
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0 == .notifications ? "Notifications" : "Accessibility" }
            .joined(separator: ", ")
    }

    private func symbol(for status: PreviewActionStatus) -> String {
        switch status {
        case .ready: return "checkmark.circle.fill"
        case .needsPermission: return "lock.circle"
        case .missingResource: return "xmark.octagon.fill"
        }
    }

    private func color(for status: PreviewActionStatus) -> Color {
        switch status {
        case .ready: return .green
        case .needsPermission: return .orange
        case .missingResource: return .red
        }
    }
}

private struct RunResultView: View {
    let record: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(statusTitle).font(.headline)
                Spacer()
                Text(String(format: "%.2fs", record.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(record.actions, id: \.index) { item in
                HStack(spacing: 8) {
                    Image(systemName: symbol(for: item.outcome))
                        .foregroundStyle(color(for: item.outcome))
                    Text("\(item.index + 1). \(title(for: item.actionID))")
                    Spacer()
                    Text(detail(for: item.outcome))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusTitle: String {
        switch record.status {
        case .succeeded: return "Succeeded"
        case .failed: return "Failed"
        case .timedOut: return "Timed out"
        case .cancelled: return "Cancelled"
        }
    }

    private func title(for id: ActionID) -> String {
        switch id {
        case .openApplication: return "Open Application"
        case .openWebsite: return "Open Website"
        case .arrangeWindow: return "Arrange Window"
        case .wait: return "Wait"
        case .showNotification: return "Show Notification"
        }
    }

    private func symbol(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        case .cancelled: return "slash.circle"
        case .notExecuted: return "circle.dashed"
        }
    }

    private func color(for outcome: ActionOutcome) -> Color {
        switch outcome {
        case .succeeded: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .notExecuted: return .gray
        }
    }

    private func detail(for outcome: ActionOutcome) -> String {
        switch outcome {
        case .succeeded: return "done"
        case .failed(let failure): return failure.message
        case .cancelled: return "cancelled"
        case .notExecuted: return "not executed"
        }
    }
}
