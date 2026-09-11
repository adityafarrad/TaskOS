import SwiftUI
import TaskOSCore

struct SidebarView: View {
    let model: ComposerViewModel
    @Binding var selection: SidebarSelection

    @State private var pendingDelete: SavedWorkflow?

    private var isWorkflowsActive: Bool {
        switch selection {
        case .destination(.workflows), .workflow:
            return true
        default:
            return false
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section {
                workflowRow
                if isWorkflowsActive {
                    workflowChildren
                }
                destinationRow(.templates)
                destinationRow(.history)
                destinationRow(.settings)
            } header: {
                brand
            } footer: {
                if model.automaticTriggersPaused {
                    Label("Automatic triggers are paused from the menu bar.", systemImage: "pause.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: TaskOSMetrics.sidebarMin, ideal: TaskOSMetrics.sidebarIdeal)
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
            Text(TaskOSInfo.displayName)
                .font(.headline)
        }
        .padding(.vertical, 6)
        .textCase(nil)
    }

    private var workflowRow: some View {
        Label(SidebarDestination.workflows.title, systemImage: SidebarPresentation.symbol(for: .workflows))
            .tag(SidebarSelection.destination(.workflows))
            .badge(model.savedWorkflows.count)
    }

    private func destinationRow(_ destination: SidebarDestination) -> some View {
        Label(destination.title, systemImage: SidebarPresentation.symbol(for: destination))
            .tag(SidebarSelection.destination(destination))
    }

    @ViewBuilder
    private var workflowChildren: some View {
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
            Button {
                model.newWorkflow()
                selection = .destination(.workflows)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New workflow (⌘N)")
            .accessibilityLabel("New workflow")
        }
        .padding(.leading, 20)
        .padding(.trailing, 2)

        ForEach(model.filteredWorkflows) { workflow in
            WorkflowSidebarRow(
                workflow: workflow,
                needsAttention: model.workflowAttention[workflow.id] != nil
            )
            .tag(SidebarSelection.workflow(workflow.id))
            .padding(.leading, 20)
            .contextMenu {
                Button("Edit") {
                    model.loadForEditing(workflow)
                    selection = .workflow(workflow.id)
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
