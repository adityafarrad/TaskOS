import AppKit
import SwiftUI

@main
struct TaskOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }

        MenuBarExtra("TaskOS") {
            MenuBarContent()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationPresenter.shared.activate()
        MenuBarViewModel.shared.load()
        MenuBarViewModel.shared.refreshStatus()
        Task {
            await AppComposition.shared.syncTriggerRegistrations()
            await AppComposition.shared.startEventTriggers()
        }
    }
}
