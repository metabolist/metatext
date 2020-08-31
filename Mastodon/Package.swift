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
    dependencies: [
        .package(path: "HTTP")
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["HTTP"]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
