import Foundation
import UniformTypeIdentifiers
import TaskOSCore

enum FileTargetValidation {
    nonisolated static func isAllowed(_ target: FileTarget) -> Bool {
        guard let url = FileTargetResolver.url(for: target) else { return false }
        return isAllowed(url)
    }

    nonisolated static func isAllowed(_ url: URL) -> Bool {
        let resolved = url.resolvingSymlinksInPath()
        if FileTarget.rejectedExtensions.contains(resolved.pathExtension.lowercased()) {
            return false
        }
        guard let values = try? resolved.resourceValues(
            forKeys: [.isDirectoryKey, .isPackageKey, .isExecutableKey, .contentTypeKey]
        ) else {
            return false
        }
        if values.isPackage == true {
            return false
        }
        if let type = values.contentType {
            if type.conforms(to: .applicationBundle)
                || type.conforms(to: .executable)
                || type.conforms(to: .script)
                || type.conforms(to: .unixExecutable) {
                return false
            }
        }
        if values.isDirectory != true, values.isExecutable == true {
            return false
        }
        return true
    }
}
