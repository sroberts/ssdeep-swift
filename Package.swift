// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SSDeep",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SSDeep",
            targets: ["SSDeep"]
        )
    ],
    targets: [
        .target(
            name: "SSDeep",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SSDeepTests",
            dependencies: ["SSDeep"]
        )
    ]
)
