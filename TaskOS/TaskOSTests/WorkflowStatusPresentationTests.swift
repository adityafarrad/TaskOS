import Foundation
import SwiftUI
import Testing
import TaskOSCore
@testable import TaskOS

@MainActor
@Suite("Workflow status presentation")
struct WorkflowStatusPresentationTests {
    private func definition(
        name: String = "Test",
        trigger: TriggerConfiguration = .manual(ManualTrigger()),
        actions: [ActionConfiguration] = [.wait(WaitAction(duration: 1))]
    ) -> AutomationDefinition {
        AutomationDefinition(name: name, trigger: trigger, actions: actions)
    }

    private func workflow(
        trigger: TriggerConfiguration = .manual(ManualTrigger()),
        isEnabled: Bool = false
    ) -> SavedWorkflow {
        SavedWorkflow(definition: definition(trigger: trigger), isEnabled: isEnabled)
    }

    @Test func manualWorkflowIsReadyToRun() {
        let status = WorkflowStatusPresentation.make(
            for: workflow(),
            needsAttention: false,
            paused: false,
            nextRun: nil
        )

        #expect(status.label == "Manual · Ready to run")
        #expect(status.detail == nil)
        #expect(!status.isAutomatic)
    }

    @Test func disabledScheduleReportsOff() {
        let schedule = ScheduleTrigger.daily(hour: 9, minute: 0)
        let status = WorkflowStatusPresentation.make(
            for: workflow(trigger: .schedule(schedule), isEnabled: false),
            needsAttention: false,
            paused: false,
            nextRun: nil
        )

        #expect(status.label == "Schedule · Off")
        #expect(status.isAutomatic)
        #expect(!status.isEnabled)
    }

    @Test func enabledScheduleShowsNextRun() {
        let schedule = ScheduleTrigger.daily(hour: 9, minute: 0)
        let nextRun = Date(timeIntervalSince1970: 1_800_000_000)
        let status = WorkflowStatusPresentation.make(
            for: workflow(trigger: .schedule(schedule), isEnabled: true),
            needsAttention: false,
            paused: false,
            nextRun: nextRun
        )

        #expect(status.label == "Schedule · On")
        #expect(status.detail?.hasPrefix("Next:") == true)
    }

    @Test func pausedScheduleIsDescribed() {
        let schedule = ScheduleTrigger.daily(hour: 9, minute: 0)
        let status = WorkflowStatusPresentation.make(
            for: workflow(trigger: .schedule(schedule), isEnabled: true),
            needsAttention: false,
            paused: true,
            nextRun: Date()
        )

        #expect(status.label == "Schedule · On")
        #expect(status.detail?.contains("Paused") == true)
    }

    @Test func attentionOverridesTint() {
        let schedule = ScheduleTrigger.daily(hour: 9, minute: 0)
        let status = WorkflowStatusPresentation.make(
            for: workflow(trigger: .schedule(schedule), isEnabled: true),
            needsAttention: true,
            paused: false,
            nextRun: Date()
        )

        #expect(status.tint == Color.orange)
    }

    @Test func lifecycleLabelsAreTruthful() {
        #expect(EditorLifecycleState.empty.label == "New workflow")
        #expect(EditorLifecycleState.draft.label == "Draft · not saved yet")
        #expect(EditorLifecycleState.unsaved.label == "Unsaved changes")
        #expect(EditorLifecycleState.savedManual.label == "Saved · Ready to run")
        #expect(EditorLifecycleState.savedAutomatic(enabled: false, paused: false).label == "Saved · Off")
        #expect(EditorLifecycleState.savedAutomatic(enabled: true, paused: false).label == "Saved · On")
        #expect(EditorLifecycleState.savedAutomatic(enabled: true, paused: true).label == "Saved · On · Paused")
    }

    @Test func viewModelLifecycleTransitions() {
        let model = ComposerViewModel()
        #expect(model.editorLifecycleState == .empty)

        model.add(.wait(1))
        #expect(model.editorLifecycleState == .unsaved)

        model.newWorkflow()
        model.setTriggerKind(.daily)
        #expect(model.editorLifecycleState == .draft)
    }

    @Test func editingSavedWorkflowReportsSavedState() {
        let model = ComposerViewModel()
        model.loadForEditing(workflow())
        #expect(model.editorLifecycleState == .savedManual)

        model.setTriggerKind(.daily)
        #expect(model.hasUnsavedChanges)
        #expect(model.editorLifecycleState == .unsaved)
    }

    @Test func savedAutomaticWorkflowReportsEnabledState() {
        let model = ComposerViewModel()
        let scheduled = workflow(trigger: .schedule(.daily(hour: 9, minute: 0)), isEnabled: true)
        model.loadForEditing(scheduled)

        #expect(model.editorLifecycleState == .savedAutomatic(enabled: true, paused: false))
    }

    @Test func blockingReasonNamesEmptySteps() {
        let model = ComposerViewModel()
        #expect(model.blockingReason == "Add at least one step to review or save.")
    }

    @Test func blockingReasonNamesTheUnresolvedStep() {
        let model = ComposerViewModel()
        model.add(.openApplication(name: "Safari", resolved: nil))
        #expect(model.blockingReason == "Step 1 needs an app.")

        model.add(.openWebsite(url: "https://", browser: nil))
        #expect(model.blockingReason == "Step 1 needs an app.")
    }

    @Test func blockingReasonNamesWebsiteAddress() {
        let model = ComposerViewModel()
        model.add(.openWebsite(url: "https://", browser: nil))
        #expect(model.blockingReason == "Step 1 needs a full http:// or https:// address.")
    }

    @Test func resolvedWorkflowHasNoBlockingReason() {
        let model = ComposerViewModel()
        model.add(.wait(1))
        #expect(model.blockingReason == nil)
    }

    @Test func blockingReasonReportsUnresolvedTrigger() {
        let model = ComposerViewModel()
        model.add(.wait(1))
        model.setTriggerFamily(.applicationLifecycle)
        #expect(model.blockingReason == "Finish configuring the trigger.")
    }

    @Test func missingRequirementDescribesFields() {
        let available: (FileTarget) -> FileTargetStatus = { _ in .available }
        #expect(ActionPresentation.missingRequirement(for: .copyText(""), fileStatus: available) == "text to copy")
        #expect(ActionPresentation.missingRequirement(for: .copyText("hi"), fileStatus: available) == nil)
        #expect(
            ActionPresentation.missingRequirement(
                for: .openWebsite(url: "not a url", browser: nil),
                fileStatus: available
            ) == "a full http:// or https:// address"
        )
        #expect(ActionPresentation.missingRequirement(for: .wait(1), fileStatus: available) == nil)
    }
}
