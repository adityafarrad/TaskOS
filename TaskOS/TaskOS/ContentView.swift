import AppKit
import SwiftUI
import TaskOSCore

struct ContentView: View {
    @State private var model = ComposerViewModel()
    @State private var selection = EditorSelection()
    @State private var sidebarSelection: SidebarSelection = .destination(.workflows)
    @State private var showReview = false
    @State private var composerFocusToken = 0

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model, selection: $sidebarSelection)
        } detail: {
            detail
                .id(sidebarSelection)
        }
        .inspector(isPresented: $selection.isInspectorPresented) {
            InspectorView(model: model, selection: selection)
                .inspectorColumnWidth(
                    min: TaskOSMetrics.inspectorMin,
                    ideal: TaskOSMetrics.inspectorIdeal
                )
        }
        .frame(minWidth: TaskOSMetrics.windowMinWidth, minHeight: TaskOSMetrics.windowMinHeight)
        .onAppear { model.loadApplicationsIfNeeded() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshAll()
        }
        .onChange(of: sidebarSelection) { _, newValue in
            handleSidebarChange(newValue)
        }
        .sheet(
            isPresented: Binding(get: { model.showOnboarding }, set: { model.showOnboarding = $0 })
        ) {
            OnboardingView { model.completeOnboarding() }
        }
        .sheet(
            isPresented: Binding(get: { model.showDiscovery }, set: { model.showDiscovery = $0 })
        ) {
            DiscoveryView(model: model)
        }
        .focusedSceneValue(\.taskOS, commandActions)
    }

    @ViewBuilder
    private var detail: some View {
        switch sidebarSelection {
        case .destination(.templates):
            TemplatesGalleryView(model: model) {
                sidebarSelection = .destination(.workflows)
            }
        case .destination(.history):
            HistoryView(model: model)
        case .destination(.settings):
            SettingsView(model: model)
        default:
            WorkflowEditorView(
                model: model,
                selection: selection,
                sidebarSelection: $sidebarSelection,
                showReview: $showReview,
                composerFocusToken: $composerFocusToken,
                onRun: run,
                onSave: { model.save() },
                onViewHistory: { sidebarSelection = .destination(.history) }
            )
        }
    }

    private var commandActions: TaskOSCommandActions {
        TaskOSCommandActions(
            newWorkflow: {
                model.newWorkflow()
                sidebarSelection = .destination(.workflows)
            },
            focusComposer: {
                sidebarSelection = .destination(.workflows)
                composerFocusToken += 1
            },
            run: {
                sidebarSelection = .destination(.workflows)
                run()
            },
            save: { model.save() },
            undo: { model.undo() },
            redo: { model.redo() },
            openSettings: { sidebarSelection = .destination(.settings) }
        )
    }

    private func run() {
        if model.canTest {
            model.test()
        } else {
            model.prepare()
            showReview = true
        }
    }

    private func handleSidebarChange(_ newValue: SidebarSelection) {
        switch newValue {
        case .workflow(let id):
            if let workflow = model.savedWorkflows.first(where: { $0.id == id }) {
                model.loadForEditing(workflow)
            }
            selection.clear()
            selection.isInspectorPresented = false
        case .destination(.workflows):
            break
        case .destination:
            selection.isInspectorPresented = false
        }
    }
}
