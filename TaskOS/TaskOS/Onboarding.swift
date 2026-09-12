import Foundation
import SwiftUI

enum OnboardingStore {
    private static let key = "TaskOS.hasCompletedOnboarding"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func complete() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func reset() {
        UserDefaults.standard.set(false, forKey: key)
    }
}

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TaskOSSpacing.lg) {
            HStack(spacing: TaskOSSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.gradient)
                    Image(systemName: "command")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to TaskOS")
                        .font(.title2.weight(.semibold))
                    Text("Automate your Mac without writing a script.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: TaskOSSpacing.sm) {
                featureRow("text.cursor", "Type what you want", "Describe a command and choose from live suggestions.")
                featureRow("square.stack.3d.up", "Review the steps", "Edit each trigger and action before anything runs.")
                featureRow("play.circle", "Preview and test", "Testing runs for real, so you always know what happens.")
                featureRow("clock.arrow.circlepath", "Save and automate", "Run manually, on a schedule, or on a system event.")
                featureRow("menubar.rectangle", "Stays in the menu bar", "TaskOS keeps running after you close the window.")
            }

            HStack {
                Spacer()
                Button("Got it") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(TaskOSSpacing.lg)
        .frame(width: 500)
    }

    private func featureRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: TaskOSSpacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
