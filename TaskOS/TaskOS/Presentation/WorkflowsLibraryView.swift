import SwiftUI
import TaskOSCore

struct WorkflowsLibraryView: View {
    let model: ComposerViewModel
    let onOpen: (SavedWorkflow) -> Void
    let onNew: () -> Void

    @State private var pendingDelete: SavedWorkflow?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaskOSSpacing.lg) {
                header

                if model.filteredWorkflows.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: TaskOSSpacing.xs) {
                        ForEach(model.filteredWorkflows) { workflow in
                            WorkflowLibraryRow(
                                workflow: workflow,
                                needsAttention: model.workflowAttention[workflow.id] != nil
                            ) {
                                onOpen(workflow)
                            }
                            .contextMenu {
                                Button("Open") { onOpen(workflow) }
                                Button("Run") { model.runSaved(workflow) }
                                Divider()
                                Button("Rename…") { model.beginRename(workflow) }
                                Button("Duplicate") { model.duplicate(workflow) }
                                Button("Export…") { model.exportWorkflow(workflow) }
                                Divider()
                                Button("Delete…", role: .destructive) { pendingDelete = workflow }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, TaskOSSpacing.xl)
            .padding(.vertical, TaskOSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Workflows")
        .accessibilityIdentifier("workflows.view")
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
                model.deleteSaved(workflow)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("This removes the workflow and cannot be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Workflows")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    onNew()
                } label: {
                    Label("New", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("workflows.new")
            }

            HStack(spacing: TaskOSSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(
                    "Search workflows",
                    text: Binding(get: { model.librarySearch }, set: { model.librarySearch = $0 })
                )
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
            .frame(maxWidth: 340)
        }
    }

    private var emptyState: some View {
        VStack(spacing: TaskOSSpacing.sm) {
            TaskOSEmptyState(
                systemImage: "square.stack.3d.up",
                title: model.savedWorkflows.isEmpty ? "No workflows yet" : "No matches",
                message: model.savedWorkflows.isEmpty
                    ? "Create your first workflow and it will appear here."
                    : "Try a different search term.",
                actionTitle: model.savedWorkflows.isEmpty ? "New Workflow" : nil,
                action: model.savedWorkflows.isEmpty ? onNew : nil
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var renamePresented: Binding<Bool> {
        Binding(
            get: { model.renameTarget != nil },
            set: { if !$0 { model.cancelRename() } }
        )
    }
}

private struct WorkflowLibraryRow: View {
    let workflow: SavedWorkflow
    let needsAttention: Bool
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: TaskOSSpacing.sm) {
                Circle()
                    .fill(needsAttention ? Color.orange : (workflow.isEnabled ? Color.green : Color.secondary.opacity(0.4)))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: TaskOSSpacing.xs) {
                        Text(workflow.name)
                            .font(.headline)
                            .lineLimit(1)
                        if needsAttention {
                            TaskOSStatusChip(text: "Needs attention", systemImage: "exclamationmark.triangle", tint: .orange)
                        }
                    }
                    HStack(spacing: TaskOSSpacing.xs) {
                        Text(workflow.definition.actions.count == 1 ? "1 step" : "\(workflow.definition.actions.count) steps")
                        Text("·")
                        Text(triggerLabel)
                        Text("·")
                        Text(workflow.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: TaskOSSpacing.xs)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(TaskOSSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .taskOSCard(isHovered: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workflow.name), \(workflow.definition.actions.count) steps")
        .accessibilityHint("Open this workflow")
    }

    private var triggerLabel: String {
        let trigger = workflow.definition.trigger
        if trigger.schedule != nil {
            return workflow.isEnabled ? "Scheduled" : "Schedule"
        }
        if trigger.isEventTrigger {
            return workflow.isEnabled ? "Automatic" : "Event"
        }
        return "Manual"
    }
}
