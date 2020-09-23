// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "HTTP",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "HTTP",
            targets: ["HTTP"]),
        .library(
            name: "Stubbing",
            targets: ["Stubbing"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HTTP",
            dependencies: []),
        .target(
            name: "Stubbing",
            dependencies: ["HTTP"]),
        .testTarget(
            name: "HTTPTests",
            dependencies: ["HTTP"])
    ]
)
