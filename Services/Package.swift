// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Services",
            targets: ["Services"]),
        .library(
            name: "ServiceMocks",
            targets: ["ServiceMocks"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/CombineExpectations.git", .upToNextMajor(from: "0.5.0")),
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.0.0-beta.10")),
        .package(path: "Mastodon")
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: ["GRDB", "Mastodon"]),
        .target(
            name: "ServiceMocks",
            dependencies: ["Services", .product(name: "MastodonStubs", package: "Mastodon")]),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["ServiceMocks", "CombineExpectations"])
    ]
)
