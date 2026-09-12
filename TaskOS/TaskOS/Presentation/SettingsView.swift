import SwiftUI
import TaskOSCore

struct SettingsView: View {
    let model: ComposerViewModel

    @State private var confirmClearHistory = false
    @State private var confirmDeleteAll = false

    var body: some View {
        Form {
            Section("Permissions") {
                permissionRow(
                    title: "Notifications",
                    state: model.notificationPermission,
                    settingsTitle: "Open Notification Settings",
                    settingsAction: { model.openNotificationSettings() }
                )
                permissionRow(
                    title: "Accessibility",
                    state: model.accessibilityPermission,
                    settingsTitle: "Open Accessibility Settings",
                    settingsAction: { model.openAccessibilitySettings() },
                    grantAction: accessibilityGrant
                )
                Button("Recheck Permissions") { model.recheckPermissions() }
            }

            Section("Startup") {
                Toggle(
                    "Launch TaskOS at login",
                    isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) })
                )
            }

            Section("Automatic triggers") {
                Toggle(
                    "Run automatic triggers",
                    isOn: Binding(
                        get: { !model.automaticTriggersPaused },
                        set: { model.setAutomaticTriggersPaused(!$0) }
                    )
                )
                if model.automaticTriggersPaused {
                    Label(
                        "Automatic triggers are paused. Scheduled and event workflows will not start.",
                        systemImage: "pause.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                } else {
                    Text("Scheduled and event workflows can start in the background.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("History") {
                Text("TaskOS keeps up to \(RunHistoryRetention.maximumRuns) runs for 30 days, whichever is reached first.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Clear History…") { confirmClearHistory = true }
            }

            Section("Help") {
                Button("Show Intro") { model.showOnboardingHelp() }
                Button("Browse Supported Actions…") { model.showDiscovery = true }
            }

            Section {
                Button("Delete All Workflows…", role: .destructive) { confirmDeleteAll = true }
            } footer: {
                Text("Creation and execution work offline. History stores operational metadata only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .accessibilityIdentifier("settings.view")
        .confirmationDialog(
            "Clear all run history?",
            isPresented: $confirmClearHistory
        ) {
            Button("Clear History", role: .destructive) { model.clearHistory() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes all recorded runs and skipped events. Your workflows are not affected.")
        }
        .confirmationDialog(
            "Delete all workflows?",
            isPresented: $confirmDeleteAll
        ) {
            Button("Delete All Workflows", role: .destructive) { model.clearAllWorkflows() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Every saved workflow and its automatic triggers will be removed. This cannot be undone.")
        }
    }

    private var accessibilityGrant: (() -> Void)? {
        guard model.accessibilityPermission != .granted else { return nil }
        return {
            model.requestAccessibilityPermission()
            model.refreshPermissions()
        }
    }

    private func permissionRow(
        title: String,
        state: PermissionState,
        settingsTitle: String,
        settingsAction: @escaping () -> Void,
        grantAction: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: TaskOSSpacing.sm) {
            Circle()
                .fill(permissionTint(state))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(permissionLabel(state))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let grantAction {
                Button("Grant", action: grantAction)
                    .controlSize(.small)
            }
            Button(settingsTitle, action: settingsAction)
                .controlSize(.small)
        }
    }

    private func permissionLabel(_ state: PermissionState) -> String {
        switch state {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .notDetermined: return "Not requested"
        }
    }

    private func permissionTint(_ state: PermissionState) -> Color {
        switch state {
        case .granted: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        }
    }
}
