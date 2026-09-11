import SwiftUI
import TaskOSCore

struct DiscoveryView: View {
    let model: ComposerViewModel
    let selection: EditorSelection
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Supported actions and triggers")
                        .font(.title3.weight(.semibold))
                    Text("Examples, parameters, permissions, and limitations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { model.showDiscovery = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(TaskOSSpacing.md)

            Divider()

            HStack(spacing: TaskOSSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: Binding(get: { model.discoverySearch }, set: { model.discoverySearch = $0 }))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, TaskOSSpacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .padding(TaskOSSpacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
                    ForEach(model.filteredGuides) { guide in
                        guideRow(guide)
                    }
                }
                .padding(.horizontal, TaskOSSpacing.md)
                .padding(.bottom, TaskOSSpacing.md)
            }
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private func guideRow(_ guide: CapabilityGuide) -> some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xxs) {
            HStack(spacing: TaskOSSpacing.xs) {
                Text(guide.title)
                    .font(.headline)
                TaskOSStatusChip(
                    text: guide.kind == .action ? "Action" : "Trigger",
                    tint: guide.kind == .action ? .blue : .purple
                )
                Spacer()
                useButton(for: guide)
            }
            Text(guide.whatItDoes)
                .font(.callout)
            Text("Example: \(guide.example)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !guide.parameters.isEmpty {
                Text("Parameters: \(guide.parameters.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !guide.permissions.isEmpty {
                Text("Permissions: \(guide.permissions.map(\.rawValue).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let limitations = guide.limitations {
                Text(limitations)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(TaskOSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .taskOSCard()
    }

    @ViewBuilder
    private func useButton(for guide: CapabilityGuide) -> some View {
        if !model.guideIsAvailable(guide) {
            TaskOSStatusChip(text: "Unavailable on this Mac", tint: .orange)
        } else if guide.kind == .trigger, triggerFamily(for: guide.id) != nil {
            Button("Use Trigger") { useTrigger(guide) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        } else if guide.kind == .action, actionDraft(for: guide.id) != nil {
            Button("Add Step") { addAction(guide) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private func useTrigger(_ guide: CapabilityGuide) {
        guard let family = triggerFamily(for: guide.id) else { return }
        model.setTriggerFamily(family)
        onEdit()
        selection.selectTrigger()
        model.showDiscovery = false
    }

    private func addAction(_ guide: CapabilityGuide) {
        guard let draft = actionDraft(for: guide.id) else { return }
        model.add(draft)
        onEdit()
    }

    private func triggerFamily(for id: String) -> ComposerViewModel.TriggerFamily? {
        switch id {
        case "trigger.manual": return .manual
        case "trigger.schedule": return .schedule
        case "trigger.applicationLifecycle": return .applicationLifecycle
        case "trigger.wake": return .wake
        case "trigger.displayConnection": return .displayConnection
        case "trigger.externalVolume": return .externalVolume
        case "trigger.powerSource": return .powerSource
        case "trigger.batteryThreshold": return .batteryThreshold
        default: return nil
        }
    }

    private func actionDraft(for id: String) -> ComposerActionDraft? {
        switch id {
        case "action.openApplication": return .openApplication(name: "", resolved: nil)
        case "action.hideApplication": return .hideApplication(name: "", resolved: nil)
        case "action.quitApplication": return .quitApplication(name: "", resolved: nil)
        case "action.openFile": return .openFile(target: nil)
        case "action.revealInFinder": return .revealInFinder(target: nil)
        case "action.openWebsite": return .openWebsite(url: "https://", browser: nil)
        case "action.arrangeWindow": return .arrangeWindow(name: "", resolved: nil, preset: .leftHalf, display: .current)
        case "action.wait": return .wait(5)
        case "action.showNotification": return .showNotification(title: "TaskOS", message: "")
        case "action.copyText": return .copyText("")
        default: return nil
        }
    }
}
