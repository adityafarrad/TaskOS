import SwiftUI
import TaskOSCore

struct ContentView: View {
    @State private var model = ReviewViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(TaskOSInfo.displayName)
                        .font(.title2)
                    Text("Review the exact steps before anything runs.")
                        .foregroundStyle(.secondary)
                }

                workflowCard
                controls

                if let preview = model.preview {
                    PreviewView(preview: preview)
                }

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
            .padding()
        }
        .frame(minWidth: 620, minHeight: 560, alignment: .topLeading)
    }

    private var workflowCard: some View {
        GroupBox("Workflow") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Trigger: \(model.definition.trigger.id == .manual ? "Manual" : model.definition.trigger.id.stableID)")
                    Spacer()
                    Text("Revision \(model.definition.revision.value)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(model.definition.actions.enumerated()), id: \.offset) { index, action in
                    Text("\(index + 1). \(Self.description(for: action))")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(model.isBusy ? "Previewing..." : "Preview") {
                model.prepare()
            }
            .disabled(model.isBusy)

            Picker("Wait", selection: waitBinding) {
                Text("1s wait").tag(1.0)
                Text("3s wait").tag(3.0)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            Button("Test now") {
                model.test()
            }
            .disabled(!model.canTest)

            Text("This runs for real.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var waitBinding: Binding<Double> {
        Binding(
            get: {
                for action in model.definition.actions {
                    if case .wait(let wait) = action {
                        return wait.duration
                    }
                }
                return 1
            },
            set: { model.setWaitDuration($0) }
        )
    }

    private static func description(for action: ActionConfiguration) -> String {
        switch action {
        case .openApplication(let configuration):
            return "Open \(configuration.application.label)"
        case .wait(let wait):
            return "Wait \(String(format: "%.1f", wait.duration))s"
        case .showNotification:
            return "Show a notification"
        }
    }
}

private struct PreviewView: View {
    let preview: WorkflowPreview

    var body: some View {
        GroupBox("Preview") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reviewed revision \(preview.revision.value)")
                        .font(.headline)
                    Spacer()
                    Text(preview.isRunnable ? "Ready to test" : "Needs attention")
                        .font(.caption)
                        .foregroundStyle(preview.isRunnable ? Color.green : Color.orange)
                }

                Text("When: \(preview.triggerTitle)")

                ForEach(preview.actions, id: \.index) { action in
                    HStack(spacing: 8) {
                        Image(systemName: symbol(for: action.status))
                            .foregroundStyle(color(for: action.status))
                        Text("\(action.index + 1). \(action.title)")
                        if let target = action.targetLabel {
                            Text("(\(target))")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let detail = action.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !preview.requiredPermissions.isEmpty {
                    Text("Permissions: \(permissionList)")
                        .font(.caption)
                }

                ForEach(Array(preview.issues.enumerated()), id: \.offset) { _, issue in
                    Label(issue.message, systemImage: issue.severity == .error ? "exclamationmark.triangle" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(issue.severity == .error ? Color.red : Color.secondary)
                }

                Text("Will run automatically: \(preview.willRunAutomatically ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                Text(statusTitle)
                    .font(.headline)
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
