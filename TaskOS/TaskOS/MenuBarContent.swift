import AppKit
import SwiftUI
import TaskOSCore

struct MenuBarContent: View {
    @State private var model = MenuBarViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open TaskOS") {
            openWindow(id: "main")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onAppear { model.load() }

        Divider()

        Menu("Run a workflow") {
            if model.workflows.isEmpty {
                Text("No saved workflows")
            } else {
                ForEach(model.workflows.prefix(10)) { workflow in
                    Button(workflow.name) {
                        model.run(workflow)
                    }
                }
            }
        }
        .disabled(model.workflows.isEmpty)

        Text("Status: \(model.status)")

        Button(model.automaticTriggersPaused ? "Resume automatic triggers" : "Pause automatic triggers") {
            model.toggleAutomaticTriggers()
        }

        Button("Cancel current run") {
            model.cancel()
        }
        .disabled(!model.isRunning)

        Divider()

        Button("Quit TaskOS") {
            model.quit()
        }
    }
}
