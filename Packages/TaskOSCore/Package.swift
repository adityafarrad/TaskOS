// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TaskOSCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TaskOSCore", targets: ["TaskOSCore"])
    ],
    targets: [
        .target(name: "TaskOSCore"),
        .testTarget(
            name: "TaskOSCoreTests",
            dependencies: ["TaskOSCore"]
        )
    ]
)
