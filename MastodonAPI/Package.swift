// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MastodonAPI",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MastodonAPI",
            targets: ["MastodonAPI"]),
        .library(
            name: "MastodonAPIStubs",
            targets: ["MastodonAPIStubs"])
    ],
    dependencies: [
        .package(path: "HTTP"),
        .package(path: "Mastodon")
    ],
    targets: [
        .target(
            name: "MastodonAPI",
            dependencies: ["HTTP", "Mastodon"]),
        .target(
            name: "MastodonAPIStubs",
            dependencies: ["MastodonAPI", .product(name: "Stubbing", package: "HTTP")],
            resources: [.process("Resources")]),
        .testTarget(
            name: "MastodonAPITests",
            dependencies: ["MastodonAPIStubs"])
    ]
)
