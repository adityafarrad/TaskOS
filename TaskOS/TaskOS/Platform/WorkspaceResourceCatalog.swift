import AppKit
import TaskOSCore

struct WorkspaceResourceCatalog: ResourceCatalog {
    nonisolated func application(bundleIdentifier: String) async -> ApplicationResource? {
        await MainActor.run {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                return nil
            }
            let fileName = FileManager.default.displayName(atPath: url.path)
            let displayName = fileName.hasSuffix(".app") ? String(fileName.dropLast(4)) : fileName
            return ApplicationResource(bundleIdentifier: bundleIdentifier, displayName: displayName)
        }
    }
}
