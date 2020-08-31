// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Mastodon",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Mastodon",
            targets: ["Mastodon"]),
        .library(
            name: "MastodonStubs",
            targets: ["MastodonStubs"])
    ],
    dependencies: [
        .package(path: "HTTP")
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["HTTP"]),
        .target(
            name: "MastodonStubs",
            dependencies: ["Mastodon", .product(name: "Stubbing", package: "HTTP")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["MastodonStubs"])
    ]
)
