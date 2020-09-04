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
        .package(path: "DB"),
        .package(path: "Keychain"),
        .package(path: "MastodonAPI"),
        .package(path: "Secrets")
    ],
    targets: [
        .target(
            name: "ServiceLayer",
            dependencies: ["DB", "MastodonAPI", "Secrets"]),
        .target(
            name: "ServiceLayerMocks",
            dependencies: [
                "ServiceLayer",
                .product(name: "MastodonAPIStubs", package: "MastodonAPI"),
                .product(name: "MockKeychain", package: "Keychain")]),
        .testTarget(
            name: "ServiceLayerTests",
            dependencies: ["CombineExpectations", "ServiceLayerMocks"])
    ]
)
