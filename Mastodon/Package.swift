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
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.2.2"))
    ],
    targets: [
        .target(
            name: "Mastodon",
            dependencies: ["Alamofire"]),
        .testTarget(
            name: "MastodonTests",
            dependencies: ["Mastodon"])
    ]
)
