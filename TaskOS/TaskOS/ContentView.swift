import AppKit
import SwiftUI
import TaskOSCore

struct ContentView: View {
    @State private var model = ComposerViewModel()
    @State private var selection = EditorSelection()
    @State private var sidebarSelection: SidebarSelection = .editor
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showReview = false
    @State private var composerFocusToken = 0
    @State private var pendingReplace: (() -> Void)?
    @State private var showDiscardPrompt = false
    @State private var contentWidth: CGFloat = 0
    @State private var appWidth: CGFloat = 0

    private var compactSidebar: Bool {
        appWidth > 0 && appWidth < 820
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                model: model,
                selection: $sidebarSelection,
                compact: compactSidebar,
                onSelect: selectSidebar,
                onNewWorkflow: newWorkflow
            )
        } detail: {
            HStack(spacing: 0) {
                detail
                    .frame(maxWidth: .infinity)

                if showsInspector {
                    Divider()
                    InspectorView(model: model, selection: selection)
                        .frame(width: inspectorWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .id(sidebarSelection)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: WindowWidthKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(WindowWidthKey.self) { contentWidth = $0 }
            .animation(.taskOSStandard, value: selection.isInspectorPresented)
        }
        .frame(minWidth: TaskOSMetrics.windowMinWidth, minHeight: TaskOSMetrics.windowMinHeight)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: AppWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(AppWidthKey.self) { appWidth = $0 }
        .onAppear { model.loadApplicationsIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshAll()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                model.refreshForAttention()
            }
        }
        .confirmationDialog(
            "You have unsaved changes",
            isPresented: $showDiscardPrompt,
            titleVisibility: .visible
        ) {
            Button("Save and Continue") { saveAndContinue() }
            Button("Discard Changes", role: .destructive) { performPendingReplace() }
            Button("Cancel", role: .cancel) { pendingReplace = nil }
        } message: {
            Text("Your current workflow has changes that haven’t been saved.")
        }
        .sheet(
            isPresented: Binding(get: { model.showOnboarding }, set: { model.showOnboarding = $0 })
        ) {
            OnboardingView { model.completeOnboarding() }
        }
        .sheet(
            isPresented: Binding(get: { model.showDiscovery }, set: { model.showDiscovery = $0 })
        ) {
            DiscoveryView(
                model: model,
                selection: selection,
                onEdit: { sidebarSelection = .editor }
            )
        }
        .focusedSceneValue(\.taskOS, commandActions)
    }

    private var isEditorDestination: Bool {
        sidebarSelection == .editor
    }

    private var showsInspector: Bool {
        selection.isInspectorPresented && isEditorDestination
    }

    private var inspectorWidth: CGFloat {
        if contentWidth == 0 {
            return TaskOSMetrics.inspectorIdeal
        }
        if contentWidth < 640 {
            return 200
        }
        if contentWidth < 820 {
            return 240
        }
        return TaskOSMetrics.inspectorIdeal
    }

    @ViewBuilder
    private var detail: some View {
        switch sidebarSelection {
        case .destination(.workflows):
            WorkflowsLibraryView(model: model, onOpen: openWorkflow, onNew: newWorkflow)
        case .destination(.templates):
            TemplatesGalleryView(model: model) { template in
                requestDocumentReplacement {
                    model.loadTemplate(template)
                    sidebarSelection = .editor
                    selection.clear()
                    selection.isInspectorPresented = false
                }
            }
        case .destination(.history):
            HistoryView(model: model)
        case .destination(.settings):
            SettingsView(model: model)
        case .editor:
            WorkflowEditorView(
                model: model,
                selection: selection,
                sidebarSelection: $sidebarSelection,
                showReview: $showReview,
                composerFocusToken: $composerFocusToken,
                onRun: run,
                onSave: { model.save() },
                onImport: { requestDocumentReplacement { model.importWorkflow() } },
                onViewHistory: { sidebarSelection = .destination(.history) }
            )
        }
    }

    private var commandActions: TaskOSCommandActions {
        TaskOSCommandActions(
            newWorkflow: newWorkflow,
            focusComposer: {
                sidebarSelection = .editor
                composerFocusToken += 1
            },
            run: {
                sidebarSelection = .editor
                run()
            },
            cancelRun: { model.cancelCurrentRun() },
            save: { model.save() },
            undo: { model.undo() },
            redo: { model.redo() },
            openSettings: { sidebarSelection = .destination(.settings) },
            browseCapabilities: {
                sidebarSelection = .editor
                model.showDiscovery = true
            }
        )
    }

    private func run() {
        guard !model.isBusy else { return }
        if model.canTest {
            model.test()
        } else {
            model.prepare()
            showReview = true
        }
    }

    private func selectSidebar(_ target: SidebarSelection) {
        guard target != sidebarSelection else { return }
        sidebarSelection = target
    }

    private func openWorkflow(_ workflow: SavedWorkflow) {
        requestDocumentReplacement {
            model.loadForEditing(workflow)
            sidebarSelection = .editor
            selection.clear()
            selection.isInspectorPresented = false
        }
    }

    private func newWorkflow() {
        requestDocumentReplacement {
            model.newWorkflow()
            sidebarSelection = .editor
            selection.clear()
            selection.isInspectorPresented = false
        }
    }

    private func requestDocumentReplacement(_ action: @escaping () -> Void) {
        guard model.hasUnsavedChanges else {
            action()
            return
        }
        pendingReplace = action
        showDiscardPrompt = true
    }

    private func performPendingReplace() {
        let action = pendingReplace
        pendingReplace = nil
        action?()
    }

    private func saveAndContinue() {
        model.save()
        performPendingReplace()
    }
}
