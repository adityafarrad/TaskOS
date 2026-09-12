import SwiftUI
import TaskOSCore

struct SidebarView: View {
    let model: ComposerViewModel
    @Binding var selection: SidebarSelection
    var compact: Bool = false
    var onSelect: (SidebarSelection) -> Void
    var onNewWorkflow: () -> Void

    @State private var pendingDelete: SavedWorkflow?

    private var isWorkflowsActive: Bool {
        switch selection {
        case .destination(.workflows), .workflow:
            return true
        default:
            return false
        }
    }

    private var sidebarMaxWidth: CGFloat? {
        compact ? 76 : nil
    }

    var body: some View {
        List {
            Section {
                destinationButton(.workflows, badge: compact ? nil : model.savedWorkflows.count)
                if isWorkflowsActive && !compact {
                    workflowChildren
                }
                destinationButton(.templates)
                destinationButton(.history)
                destinationButton(.settings)
                if compact {
                    compactNewWorkflowButton
                }
            } header: {
                brand
            } footer: {
                if !compact, model.automaticTriggersPaused {
                    Label("Automatic triggers are paused from the menu bar.", systemImage: "pause.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(
            min: compact ? 56 : TaskOSMetrics.sidebarMin,
            ideal: compact ? 64 : TaskOSMetrics.sidebarIdeal,
            max: sidebarMaxWidth
        )
        .alert("Rename Workflow", isPresented: renamePresented) {
            TextField("Name", text: Binding(get: { model.renameText }, set: { model.renameText = $0 }))
            Button("Save") { model.commitRename() }
            Button("Cancel", role: .cancel) { model.cancelRename() }
        }
        .confirmationDialog(
            "Delete “\(pendingDelete?.name ?? "")”?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { workflow in
            Button("Delete", role: .destructive) {
                if selection == .workflow(workflow.id) {
                    onSelect(.destination(.workflows))
                }
                model.deleteSaved(workflow)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("This removes the workflow and cannot be undone.")
        }
    }

    private var brand: some View {
        HStack(spacing: TaskOSSpacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.gradient)
                Image(systemName: "command")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 24, height: 24)
            if !compact {
                Text(TaskOSInfo.displayName)
                    .font(.headline)
            }
        }
        .frame(maxWidth: compact ? .infinity : nil, alignment: compact ? .center : .leading)
        .padding(.vertical, 6)
        .textCase(nil)
    }

    private func isDestinationSelected(_ destination: SidebarDestination) -> Bool {
        selection == .destination(destination)
    }

    private func destinationButton(_ destination: SidebarDestination, badge: Int? = nil) -> some View {
        Button {
            onSelect(.destination(destination))
        } label: {
            if compact {
                Image(systemName: SidebarPresentation.symbol(for: destination))
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            } else {
                HStack(spacing: TaskOSSpacing.xs) {
                    Label(destination.title, systemImage: SidebarPresentation.symbol(for: destination))
                    Spacer(minLength: 0)
                    if let badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(rowBackground(isSelected: isDestinationSelected(destination)))
        .accessibilityAddTraits(isDestinationSelected(destination) ? [.isSelected] : [])
        .accessibilityLabel(destination.title)
        .accessibilityIdentifier("sidebar.\(destination.rawValue)")
    }

    private var compactNewWorkflowButton: some View {
        Button {
            onNewWorkflow()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .help("New workflow (⌘N)")
        .accessibilityLabel("New workflow")
        .accessibilityIdentifier("sidebar.newWorkflow")
    }

    @ViewBuilder
    private func rowBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.accentColor.opacity(0.16))
                .padding(.horizontal, 4)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var workflowChildren: some View {
        Button {
            onNewWorkflow()
        } label: {
            HStack(spacing: TaskOSSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
                Text("New Workflow")
                    .fontWeight(.medium)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
        .listRowBackground(Color.clear)
        .help("New workflow (⌘N)")
        .accessibilityIdentifier("sidebar.newWorkflow")

        HStack(spacing: TaskOSSpacing.xxs) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(
                "Search",
                text: Binding(get: { model.librarySearch }, set: { model.librarySearch = $0 })
            )
            .textFieldStyle(.plain)
            .font(.subheadline)
        }
        .padding(.leading, 20)
        .padding(.trailing, 2)

        ForEach(model.filteredWorkflows) { workflow in
            Button {
                onSelect(.workflow(workflow.id))
            } label: {
                WorkflowSidebarRow(
                    workflow: workflow,
                    needsAttention: model.workflowAttention[workflow.id] != nil
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .listRowBackground(rowBackground(isSelected: selection == .workflow(workflow.id)))
            .accessibilityIdentifier("sidebar.workflow.\(workflow.name)")
            .contextMenu {
                Button("Edit") {
                    onSelect(.workflow(workflow.id))
                }
                Button("Run") { model.runSaved(workflow) }
                Divider()
                Button("Rename…") { model.beginRename(workflow) }
                Button("Duplicate") { model.duplicate(workflow) }
                Button("Export…") { model.exportWorkflow(workflow) }
                Divider()
                Button("Delete…", role: .destructive) { pendingDelete = workflow }
            }
        }

        if model.filteredWorkflows.isEmpty, !model.librarySearch.isEmpty {
            Text("No matches")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 20)
        }
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { model.renameTarget != nil },
            set: { if !$0 { model.cancelRename() } }
        )
    }
}

private struct WorkflowSidebarRow: View {
    let workflow: SavedWorkflow
    let needsAttention: Bool

    var body: some View {
        HStack(spacing: TaskOSSpacing.xs) {
            Circle()
                .fill(needsAttention ? Color.orange : (workflow.isEnabled ? Color.green : Color.secondary.opacity(0.4)))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 0) {
                Text(workflow.name)
                    .lineLimit(1)
                Text(workflow.definition.actions.count == 1 ? "1 step" : "\(workflow.definition.actions.count) steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: TaskOSSpacing.xxs)

            if needsAttention {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .help("Needs attention")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workflow.name), \(workflow.isEnabled ? "enabled" : "manual")")
    }
}
