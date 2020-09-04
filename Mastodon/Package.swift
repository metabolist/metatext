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
            targets: ["Mastodon"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Mastodon"),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
