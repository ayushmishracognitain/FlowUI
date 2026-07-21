// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FlowUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The schema and decoding layer. UI targets build on top of this.
        .library(name: "FlowCore", targets: ["FlowCore"])
    ],
    targets: [
        .target(
            name: "FlowCore"
        ),
        .testTarget(
            name: "FlowCoreTests",
            dependencies: ["FlowCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
