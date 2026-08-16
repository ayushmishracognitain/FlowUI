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
    dependencies: [
        // Local and SPI DocC builds: `swift package generate-documentation`.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "FlowCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FlowRender",
            dependencies: ["FlowCore"],
            // Flow-UI collects nothing, but an SDK is expected to say so out loud.
            resources: [.copy("PrivacyInfo.xcprivacy")],
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
        ),
        .testTarget(
            name: "FlowWidgetsTests",
            dependencies: ["FlowWidgets"],
            swiftSettings: swiftSettings
        )
    ]
)
