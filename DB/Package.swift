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
        .package(name: "GRDB", url: "https://github.com/metabolist/GRDB.swift.git", .revision("c326f8b")),
        .package(path: "Mastodon"),
        .package(path: "Secrets")
    ],
    targets: [
        .target(
            name: "DB",
            dependencies: ["GRDB", "Mastodon", "Secrets"]),
        .testTarget(
            name: "DBTests",
            dependencies: ["DB"])
    ]
)
