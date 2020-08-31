// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ServiceLayer",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "ServiceLayer",
            targets: ["ServiceLayer"]),
        .library(
            name: "ServiceLayerMocks",
            targets: ["ServiceLayerMocks"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/CombineExpectations.git", .upToNextMajor(from: "0.5.0")),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.0.0-beta.10")),
        .package(path: "Mastodon")
    ],
    targets: [
        .target(
            name: "ServiceLayer",
            dependencies: ["GRDB", "Mastodon"]),
        .target(
            name: "ServiceLayerMocks",
            dependencies: ["ServiceLayer", .product(name: "MastodonStubs", package: "Mastodon")]),
        .testTarget(
            name: "ServiceLayerTests",
            dependencies: ["CombineExpectations", "ServiceLayerMocks"])
    ]
)
