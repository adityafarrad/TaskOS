import SwiftUI
import TaskOSCore

struct WorkflowEditorView: View {
    let model: ComposerViewModel
    let selection: EditorSelection
    @Binding var sidebarSelection: SidebarSelection
    @Binding var showReview: Bool
    @Binding var composerFocusToken: Int
    let onRun: () -> Void
    let onSave: () -> Void
    let onImport: () -> Void
    let onViewHistory: () -> Void

    @FocusState private var composerFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingDelete: SavedWorkflow?

    private var finishedRecord: RunRecord? {
        if case .finished(let record) = model.stage,
           record.automationID == model.currentAutomationID {
            return record
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TaskOSSpacing.md) {
                titleHeader

                triggerRow

                CommandComposerView(
                    model: model,
                    isFocused: $composerFocused,
                    onBrowseActions: { model.showDiscovery = true }
                )

                if model.isRunning {
                    runningBanner
                } else if let record = finishedRecord {
                    RunBannerView(
                        record: record,
                        onViewHistory: onViewHistory,
                        onDismiss: { model.dismissResult() }
                    )
                }

                if isEmptyWorkflow {
                    quickStart
                }

                stepsSection

                if let notice = model.notice {
                    noticeRow(notice)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, TaskOSSpacing.xl)
            .padding(.vertical, TaskOSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .toolbar { toolbarContent }
        .navigationTitle(model.draftName)
        .accessibilityIdentifier("editor.view")
        .safeAreaInset(edge: .bottom) { editorActionBar }
        .onChange(of: composerFocusToken) { _, _ in
            composerFocused = true
        }
        .alert(
            "Delete Workflow?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { workflow in
            Button("Delete", role: .destructive) {
                sidebarSelection = .destination(.workflows)
                model.deleteSaved(workflow)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { workflow in
            Text("“\(workflow.name)” and its history metadata will be removed. This cannot be undone.")
        }
    }

    private var editorActionBar: some View {
        HStack(spacing: TaskOSSpacing.sm) {
            Image(systemName: model.hasUnsavedChanges ? "pencil.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(model.hasUnsavedChanges ? Color.orange : Color.green)
                .font(.system(size: 15))

            Text(model.hasUnsavedChanges ? "Unsaved changes" : "All changes saved")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Review") { showReview = true }
                .disabled(model.actions.isEmpty)

            Button("Save") { onSave() }
                .buttonStyle(.borderedProminent)
                .disabled(!model.hasUnsavedChanges)
                .accessibilityIdentifier("editor.saveBottom")
        }
        .padding(.horizontal, TaskOSSpacing.lg)
        .padding(.vertical, TaskOSSpacing.xs)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var runningBanner: some View {
        HStack(spacing: TaskOSSpacing.sm) {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 1) {
                Text(model.runningName.map { "Running \($0)…" } ?? "Running…")
                    .font(.subheadline.weight(.semibold))
                if model.queuedCount > 0 {
                    Text(model.queuedCount == 1 ? "1 run queued" : "\(model.queuedCount) runs queued")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Cancel") { model.cancelCurrentRun() }
                .controlSize(.small)
        }
        .padding(.horizontal, TaskOSSpacing.md)
        .padding(.vertical, TaskOSSpacing.xs)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var triggerRow: some View {
        HStack(alignment: .center, spacing: TaskOSSpacing.sm) {
            Text("When")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            triggerPill

            Spacer(minLength: TaskOSSpacing.xs)

            Button {
                model.showDiscovery = true
            } label: {
                Label("Actions & Triggers", systemImage: "list.bullet.rectangle")
                    .font(.caption)
            }
            .buttonStyle(.link)
            .help("Browse every supported action and trigger")
            .accessibilityIdentifier("editor.capabilities")
        }
    }

    private var isEmptyWorkflow: Bool {
        model.actions.isEmpty
            && model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
            Text("Get started")
                .font(.headline)
            Text("Describe what you want above, start from a template, or browse every supported action and trigger.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: TaskOSSpacing.sm) {
                Button {
                    model.showDiscovery = true
                } label: {
                    Label("Browse Actions & Triggers", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    sidebarSelection = .destination(.templates)
                } label: {
                    Label("Browse Templates", systemImage: "square.grid.2x2")
                }
            }

            VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
                Text("Popular triggers")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: TaskOSSpacing.xs) {
                    triggerChip(.manual, "Run manually")
                    triggerChip(.schedule, "On a schedule")
                    triggerChip(.applicationLifecycle, "When an app opens")
                    triggerChip(.wake, "When the Mac wakes")
                }
            }
        }
        .padding(TaskOSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private func triggerChip(_ family: ComposerViewModel.TriggerFamily, _ title: String) -> some View {
        Button {
            model.setTriggerFamily(family)
            selection.selectTrigger()
        } label: {
            Label(title, systemImage: TriggerPresentation.symbol(for: family))
                .font(.caption)
        }
        .buttonStyle(.bordered)
    }

    private var triggerPill: some View {
        Menu {
            ForEach(triggerFamilies, id: \.self) { family in
                Button {
                    model.setTriggerFamily(family)
                    selection.selectTrigger()
                } label: {
                    Label(TriggerPresentation.title(for: family), systemImage: TriggerPresentation.symbol(for: family))
                }
            }
            Divider()
            Button("Configure Trigger…") { selection.selectTrigger() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: TriggerPresentation.symbol(for: model.triggerFamily))
                    .font(.system(size: 11, weight: .semibold))
                Text(TriggerPresentation.title(for: model.triggerFamily))
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Change when this workflow runs")
        .accessibilityLabel("Trigger: \(TriggerPresentation.title(for: model.triggerFamily))")
        .accessibilityIdentifier("editor.triggerPill")
    }

    private var triggerFamilies: [ComposerViewModel.TriggerFamily] {
        [.manual, .schedule, .applicationLifecycle, .wake, .displayConnection, .externalVolume, .powerSource, .batteryThreshold]
    }

    private var titleHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: TaskOSSpacing.sm) {
            TextField(
                "Untitled Workflow",
                text: Binding(get: { model.draftName }, set: { model.updateName($0) })
            )
            .textFieldStyle(.plain)
            .font(.system(size: 26, weight: .semibold))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Workflow name")
            .accessibilityIdentifier("editor.title")

            if model.supportsAutomaticRuns {
                Toggle(
                    model.activeWorkflow == nil ? "Run automatically" : "Enabled",
                    isOn: enabledBinding
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .fixedSize()
                .help(model.activeWorkflow == nil ? "Run automatically after saving" : "Enable or disable this workflow")
                .accessibilityLabel("Enabled")
            }
        }
        .padding(.vertical, 2)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: {
                if let workflow = model.activeWorkflow {
                    return workflow.isEnabled
                }
                return model.autoRunEnabled
            },
            set: { newValue in
                if let workflow = model.activeWorkflow {
                    model.setEnabled(workflow, enabled: newValue)
                } else {
                    model.autoRunEnabled = newValue
                }
            }
        )
    }

    @ViewBuilder
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.xs) {
            TaskOSSectionHeader(title: "Steps") {
                Text(model.actions.count == 1 ? "1 step" : "\(model.actions.count) steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if model.actions.isEmpty {
                emptySteps
            } else {
                VStack(spacing: TaskOSSpacing.xs) {
                    ForEach(Array(model.actions.enumerated()), id: \.element.id) { index, action in
                        StepCardView(
                            index: index,
                            action: action,
                            model: model,
                            isSelected: selection.selectedStepID == action.id,
                            onSelect: { selection.selectStep(action.id) },
                            onMoveUp: { model.moveUp(id: action.id) },
                            onMoveDown: { model.moveDown(id: action.id) },
                            onDuplicate: {
                                model.duplicateAction(id: action.id)
                            },
                            onDelete: {
                                model.remove(id: action.id)
                                selection.stepWasRemoved(action.id)
                            }
                        )
                        .dropDestination(for: String.self) { items, _ in
                            guard let raw = items.first,
                                  let draggedID = UUID(uuidString: raw),
                                  let from = model.actions.firstIndex(where: { $0.id == draggedID }) else {
                                return false
                            }
                            withAnimation(reduceMotion ? nil : .taskOSStandard) {
                                model.moveActions(fromOffsets: IndexSet(integer: from), toOffset: index)
                            }
                            return true
                        }
                    }
                }
                .animation(reduceMotion ? nil : .taskOSStandard, value: model.actions.map(\.id))
            }

            addStepMenu
                .padding(.top, 2)
        }
    }

    private var emptySteps: some View {
        HStack(spacing: TaskOSSpacing.sm) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 18))
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text("No steps yet")
                    .font(.subheadline.weight(.medium))
                Text("Describe what you want above, or add a step below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(TaskOSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: TaskOSRadius.card, style: .continuous))
    }

    private var addStepMenu: some View {
        Menu {
            Button("Open a website") { model.add(.openWebsite(url: "https://", browser: nil)) }
            Button("Open a file or folder") { model.add(.openFile(target: nil)) }
            Button("Reveal in Finder") { model.add(.revealInFinder(target: nil)) }
            Button("Hide an application") { model.add(.hideApplication(name: "", resolved: nil)) }
            Button("Quit an application") { model.add(.quitApplication(name: "", resolved: nil)) }
            Button("Arrange a window") {
                model.add(.arrangeWindow(name: "", resolved: nil, preset: .leftHalf, display: .current))
            }
            Button("Wait 1 second") { model.add(.wait(1)) }
            Button("Wait 5 seconds") { model.add(.wait(5)) }
            Button("Show a notification") {
                model.add(.showNotification(title: "TaskOS", message: ""))
            }
            Button("Copy text") {
                model.add(.copyText(""))
            }
        } label: {
            Label("Add step", systemImage: "plus")
        }
        .fixedSize()
        .accessibilityIdentifier("editor.addStep")
    }

    private func noticeRow(_ notice: String) -> some View {
        Label(notice, systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TaskOSSpacing.sm)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if model.hasUnsavedChanges {
                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .help("Save workflow (⌘S)")
                .accessibilityIdentifier("editor.save")
            }

            Button {
                onRun()
            } label: {
                if model.isRunning {
                    Label("Running", systemImage: "hourglass")
                } else {
                    Label("Run", systemImage: "play.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy)
            .help(model.isRunning ? "Running…" : "Run workflow (⌘R)")
            .accessibilityIdentifier("editor.run")
            .popover(isPresented: $showReview, arrowEdge: .bottom) {
                RunReviewView(
                    model: model,
                    onSave: {
                        onSave()
                        showReview = false
                    },
                    onRun: {
                        showReview = false
                        model.test()
                    },
                    onDismiss: { showReview = false }
                )
            }

            Menu {
                moreActions
            } label: {
                Label("More", systemImage: "ellipsis")
            }
            .menuIndicator(.hidden)
            .help("More actions")

            Button {
                selection.isInspectorPresented.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Show or hide the inspector")
            .accessibilityIdentifier("inspectorToggle")
        }
    }

    @ViewBuilder
    private var moreActions: some View {
        Button("Review Workflow…") { showReview = true }

        if let workflow = model.activeWorkflow {
            Divider()
            Button("Rename…") { model.beginRename(workflow) }
            Button("Duplicate") { model.duplicate(workflow) }
            Button("Export…") { model.exportWorkflow(workflow) }
            Divider()
            Button("Delete…", role: .destructive) { pendingDelete = workflow }
        }

        Divider()
        Button("Actions & Triggers…") { model.showDiscovery = true }
        Button("Import Workflow…") { onImport() }
        Button("Save") { onSave() }
            .disabled(!model.hasUnsavedChanges)
    }
}
