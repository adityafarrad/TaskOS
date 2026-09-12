import Foundation
import TaskOSCore

enum FileTargetStatus: Equatable {
    case available
    case moved(String)
    case missing
}

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

    static func status(_ target: FileTarget) -> FileTargetStatus {
        guard let url = url(for: target) else { return .missing }
        guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
        if !target.path.isEmpty, url.path != target.path {
            return .moved(url.lastPathComponent)
        }
        return .available
    }
}
