import SwiftUI
import TaskOSCore

struct RunReviewView: View {
    let model: ComposerViewModel
    var onSave: () -> Void
    var onRun: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
            HStack(spacing: TaskOSSpacing.xs) {
                Image(systemName: "play.circle")
                    .foregroundStyle(.secondary)
                Text("Review workflow")
                    .font(.headline)
                Spacer()
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let preview = model.preview {
                PreviewSummary(preview: preview)
            } else if model.isBusy {
                Text("Preparing the exact steps…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(model.notice ?? "Finish resolving every step before running.")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            if let preview = model.preview,
               preview.requiredPermissions.contains(.accessibility) {
                Button("Grant Accessibility") { model.requestAccessibilityPermission() }
                    .controlSize(.small)
            }

            Divider()

            HStack {
                Text("Testing runs for real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSave() }
                    .disabled(!model.canPrepare)
                Button("Run once") { onRun() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canTest)
            }
        }
        .padding(TaskOSSpacing.md)
        .frame(width: 400)
    }
}

struct PreviewSummary: View {
    let preview: WorkflowPreview

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            HStack {
                Label(
                    preview.isRunnable ? "Ready to test" : "Needs attention",
                    systemImage: preview.isRunnable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(preview.isRunnable ? Color.green : Color.orange)
                Spacer()
                Text("Revision \(preview.revision.value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Text("When: \(preview.triggerTitle)")
                .font(.callout)

            ForEach(preview.actions, id: \.index) { action in
                HStack(spacing: TaskOSSpacing.xs) {
                    Image(systemName: symbol(for: action.status))
                        .foregroundStyle(color(for: action.status))
                    Text("\(action.index + 1). \(action.title)")
                        .font(.callout)
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

struct RunResultView: View {
    let record: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            HStack {
                Text(RunPresentation.title(for: record.status))
                    .font(.headline)
                    .foregroundStyle(RunPresentation.tint(for: record.status))
                Spacer()
                Text(String(format: "%.2f s", record.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(RunPresentation.summary(for: record))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(record.actions, id: \.index) { item in
                HStack(spacing: TaskOSSpacing.xs) {
                    Image(systemName: RunPresentation.symbol(for: item.outcome))
                        .foregroundStyle(RunPresentation.tint(for: item.outcome))
                    Text("\(item.index + 1). \(ActionPresentation.title(for: item.actionID))")
                    Spacer()
                    Text(RunPresentation.detail(for: item.outcome))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RunBannerView: View {
    let record: RunRecord
    var onViewHistory: () -> Void
    var onDismiss: () -> Void
    var onFixPermission: ((PermissionKind) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: TaskOSSpacing.sm) {
            Image(systemName: RunPresentation.symbol(for: record.status))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RunPresentation.tint(for: record.status))

            VStack(alignment: .leading, spacing: 1) {
                Text(RunPresentation.title(for: record.status))
                    .font(.subheadline.weight(.semibold))
                Text(RunPresentation.summary(for: record))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("\(record.automationName) · \(String(format: "%.2f s", record.duration))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if let fix = RunPresentation.permissionFix(for: record), let onFixPermission {
                Button(fix == .accessibility ? "Accessibility Settings" : "Notification Settings") {
                    onFixPermission(fix)
                }
                .controlSize(.small)
            }

            Button("View in History", action: onViewHistory)
                .controlSize(.small)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .accessibilityLabel("Dismiss run result")
        }
        .padding(.horizontal, TaskOSSpacing.md)
        .padding(.vertical, TaskOSSpacing.xs)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
    }
}
