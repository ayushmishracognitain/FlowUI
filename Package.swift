// swift-tools-version: 6.0

import PackageDescription

// Every target builds in the Swift 6 language mode. The framework hands widget
// payloads to a background decode and widget views back to the main actor, so the
// isolation needs to be checked rather than assumed.
let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6)
]

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
            name: "FlowCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FlowRender",
            dependencies: ["FlowCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FlowWidgets",
            dependencies: ["FlowRender"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FlowCoreTests",
            dependencies: ["FlowCore"],
            resources: [.copy("Fixtures")],
            swiftSettings: swiftSettings
        )
    ]
)
