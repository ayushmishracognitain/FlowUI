// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FlowUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // The umbrella product most apps should import.
        .library(name: "FlowUI", targets: ["FlowCore", "FlowRender", "FlowWidgets"]),
        // The schema and decoding layer on its own, useful for tooling and backend tests.
        .library(name: "FlowCore", targets: ["FlowCore"]),
        // The SwiftUI rendering layer without the starter widgets.
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
        .target(
            name: "FlowWidgets",
            dependencies: ["FlowRender"]
        ),
        .testTarget(
            name: "FlowCoreTests",
            dependencies: ["FlowCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
