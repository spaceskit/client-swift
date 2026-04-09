// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "SpaceskitClient",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SpaceskitClient",
            targets: ["SpaceskitClient"]
        ),
    ],
    targets: [
        .target(
            name: "SpaceskitClient",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SpaceskitClientTests",
            dependencies: ["SpaceskitClient"],
            resources: [
                .process("Fixtures"),
            ]
        ),
    ]
)
