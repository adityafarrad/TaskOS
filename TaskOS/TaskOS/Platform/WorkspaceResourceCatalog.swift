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
        Self.applicationRecords(in: [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ])
    }

    nonisolated static func applicationRecords(in roots: [URL]) -> [ApplicationRecord] {
        var collected: [ApplicationRecord] = []
        for root in roots {
            collectApplications(in: root, depth: 0, into: &collected)
            if collected.count >= CommandLimits.maximumApplications { break }
        }

        var seen = Set<String>()
        return collected
            .filter { seen.insert($0.bundleIdentifier).inserted }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private static func collectApplications(in directory: URL, depth: Int, into collected: inout [ApplicationRecord]) {
        guard depth <= Self.maximumDiscoveryDepth, collected.count < CommandLimits.maximumApplications else { return }
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys
        ) else {
            return
        }

        for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            if entry.lastPathComponent.hasPrefix(".") { continue }
            if entry.pathExtension == "app" {
                if let record = applicationRecord(for: entry) {
                    collected.append(record)
                }
                continue
            }
            let values = try? entry.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == true, values?.isPackage != true {
                collectApplications(in: entry, depth: depth + 1, into: &collected)
            }
        }
    }

    private static func applicationRecord(for entry: URL) -> ApplicationRecord? {
        guard let bundle = Bundle(url: entry), let identifier = bundle.bundleIdentifier else {
            return nil
        }
        let fileName = entry.deletingPathExtension().lastPathComponent
        let displayName = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? fileName
        return ApplicationRecord(
            bundleIdentifier: identifier,
            displayName: displayName,
            fileName: fileName,
            url: entry,
            aliases: approvedAliases[identifier] ?? []
        )
    }

    private static let maximumDiscoveryDepth = 3
}
