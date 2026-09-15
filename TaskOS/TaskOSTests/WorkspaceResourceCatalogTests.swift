import Testing
import Foundation
import TaskOSCore
@testable import TaskOS

@Suite("Workspace resource catalog")
struct WorkspaceResourceCatalogTests {
    private func makeApplicationBundle(at url: URL, identifier: String, name: String) throws {
        let contents = url.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info: [String: Any] = [
            "CFBundleIdentifier": identifier,
            "CFBundleName": name,
            "CFBundlePackageType": "APPL",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
    }

    @Test func discoversApplicationsInNestedVendorFolders() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }

        let nested = root.appendingPathComponent("Vendor/Product.app")
        try makeApplicationBundle(at: nested, identifier: "com.example.product", name: "Product")

        let records = WorkspaceResourceCatalog.applicationRecords(in: [root])
        #expect(records.map(\.bundleIdentifier) == ["com.example.product"])
    }

    @Test func discoversApplicationsAtTheRoot() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }

        let app = root.appendingPathComponent("Root.app")
        try makeApplicationBundle(at: app, identifier: "com.example.root", name: "Root")

        let records = WorkspaceResourceCatalog.applicationRecords(in: [root])
        #expect(records.map(\.bundleIdentifier) == ["com.example.root"])
    }
}
