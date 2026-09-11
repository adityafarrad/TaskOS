import Foundation
import TaskOSCore

enum FileTargetResolver {
    static func url(for target: FileTarget) -> URL? {
        if let bookmark = target.bookmark {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                return url
            }
        }
        guard !target.path.isEmpty else { return nil }
        return URL(fileURLWithPath: target.path)
    }

    static func exists(_ target: FileTarget) -> Bool {
        guard let url = url(for: target) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
