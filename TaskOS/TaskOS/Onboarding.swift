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
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to TaskOS")
                .font(.title2)

            Text("Start typing what you want your Mac to do, for example \"open Safari and put it on the left half\".")
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Label("Choose suggestions and edit the live step cards.", systemImage: "text.cursor")
                Label("Preview and test the exact steps before you save.", systemImage: "play.circle")
                Label("Start with a Template, or type a trigger like \"every weekday at 9\" or \"when Safari opens\".", systemImage: "square.grid.2x2")
                Label("Choose \"Browse supported actions\" to see examples, permissions, and limitations.", systemImage: "magnifyingglass")
                Label("TaskOS keeps running in the menu bar after you close the window.", systemImage: "menubar.rectangle")
                Label("Arranging windows needs Accessibility permission, granted from Preview or Settings.", systemImage: "lock.shield")
            }
            .font(.callout)

            HStack {
                Spacer()
                Button("Got it") { onDismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
