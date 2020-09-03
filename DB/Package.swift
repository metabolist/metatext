// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "DB",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "DB",
            targets: ["DB"])
    ],
    dependencies: [
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.0.0-beta.10")),
        .package(path: "Mastodon")
    ],
    targets: [
        .target(
            name: "DB",
            dependencies: ["GRDB", "Mastodon"]),
        .testTarget(
            name: "DBTests",
            dependencies: ["DB"])
    ]
)
