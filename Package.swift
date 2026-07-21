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
        .library(name: "FlowCore", targets: ["FlowCore"]),
        // The SwiftUI rendering layer.
        .library(name: "FlowRender", targets: ["FlowRender"])
    ],
    targets: [
        .target(
            name: "FlowCore"
        ),
        .target(
            name: "FlowRender",
            dependencies: ["FlowCore"]
        ),
        .testTarget(
            name: "FlowCoreTests",
            dependencies: ["FlowCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
