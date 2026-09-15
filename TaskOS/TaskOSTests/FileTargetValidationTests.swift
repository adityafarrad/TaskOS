import Testing
import Foundation
@testable import TaskOS

@Suite("File target validation")
struct FileTargetValidationTests {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func regularFilesAndFoldersAreAllowed() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: file)
        let folder = root.appendingPathComponent("Projects")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        #expect(FileTargetValidation.isAllowed(file))
        #expect(FileTargetValidation.isAllowed(folder))
    }

    @Test func executableFilesAreRejected() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let tool = root.appendingPathComponent("tool")
        try Data("#!/bin/sh\n".utf8).write(to: tool)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)

        #expect(!FileTargetValidation.isAllowed(tool))
    }

    @Test func applicationBundlesAreRejected() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let app = root.appendingPathComponent("Fake.app")
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)

        #expect(!FileTargetValidation.isAllowed(app))
    }

    @Test func rejectedExtensionsAreRejected() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        for name in ["install.sh", "package.pkg", "image.dmg", "script.command"] {
            let file = root.appendingPathComponent(name)
            try Data("x".utf8).write(to: file)
            #expect(!FileTargetValidation.isAllowed(file), "\(name) should be rejected")
        }
    }

    @Test func symlinksToExecutablesAreRejected() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let real = root.appendingPathComponent("binary")
        try Data("x".utf8).write(to: real)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: real.path)

        let link = root.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        #expect(!FileTargetValidation.isAllowed(link))
    }
}
