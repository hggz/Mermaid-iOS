// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MermaidSwift",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "MermaidSwift",
            targets: ["MermaidSwift"]
        ),
    ],
    targets: [
        .target(
            name: "MermaidSwift",
            path: "Sources/MermaidSwift",
            swiftSettings: [
                .enableExperimentalFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "MermaidSwiftTests",
            dependencies: ["MermaidSwift"],
            path: "Tests/MermaidSwiftTests"
        ),
    ]
)
