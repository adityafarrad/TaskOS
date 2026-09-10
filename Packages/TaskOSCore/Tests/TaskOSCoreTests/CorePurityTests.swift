import Testing
import Foundation

@Suite("Core purity")
struct CorePurityTests {
    private static let forbiddenFrameworks = [
        "SwiftUI",
        "AppKit",
        "SwiftData",
        "UIKit",
        "Cocoa",
        "UserNotifications",
    ]

    @Test func coreSourcesDoNotImportPresentationOrPlatformFrameworks() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourcesRoot = packageRoot.appendingPathComponent("Sources/TaskOSCore")

        let files = try FileManager.default.contentsOfDirectory(
            at: sourcesRoot,
            includingPropertiesForKeys: nil
        )

        var inspected = 0
        for file in files where file.pathExtension == "swift" {
            inspected += 1
            let contents = try String(contentsOf: file, encoding: .utf8)
            for framework in Self.forbiddenFrameworks {
                #expect(
                    !contents.contains("import \(framework)"),
                    "\(file.lastPathComponent) must not import \(framework)"
                )
            }
        }

        #expect(inspected > 0, "Expected to inspect at least one Core source file")
    }
}
