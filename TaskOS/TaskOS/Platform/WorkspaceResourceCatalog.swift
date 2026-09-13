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

    nonisolated func fileExists(path: String) async -> Bool? {
        guard !path.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    nonisolated func installedDisplays() async -> [DisplayResource] {
        await MainActor.run {
            NSScreen.screens.compactMap { screen in
                guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                    return nil
                }
                return DisplayResource(
                    identifier: number.stringValue,
                    displayName: screen.localizedName,
                    isMain: screen == NSScreen.main
                )
            }
        }
    }

    nonisolated func installedApplications() async -> [ApplicationResource] {
        await installedApplicationRecords().map(\.resource)
    }

    private static let approvedAliases: [String: [String]] = [
        "com.microsoft.VSCode": ["VS Code", "VSCode"],
        "com.google.Chrome": ["Chrome"],
        "com.apple.Safari": ["Safari"],
    ]

    nonisolated func installedApplicationRecords() async -> [ApplicationRecord] {
        let fileManager = FileManager.default
        let directories = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        var collected: [ApplicationRecord] = []

        for directory in directories {
            guard let entries = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ) else {
                continue
            }

            for entry in entries where entry.pathExtension == "app" {
                guard let bundle = Bundle(url: entry), let identifier = bundle.bundleIdentifier else {
                    continue
                }
                let fileName = entry.deletingPathExtension().lastPathComponent
                let displayName = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
                    ?? (bundle.infoDictionary?["CFBundleName"] as? String)
                    ?? fileName
                collected.append(
                    ApplicationRecord(
                        bundleIdentifier: identifier,
                        displayName: displayName,
                        fileName: fileName,
                        url: entry,
                        aliases: Self.approvedAliases[identifier] ?? []
                    )
                )
            }
        }

        var seen = Set<String>()
        return collected
            .filter { seen.insert($0.bundleIdentifier).inserted }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
