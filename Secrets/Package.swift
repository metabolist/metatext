// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Secrets",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Secrets",
            targets: ["Secrets"])
    ],
    dependencies: [
        .package(path: "Base16"),
        .package(path: "Keychain")
    ],
    targets: [
        .target(
            name: "Secrets",
            dependencies: ["Base16", "Keychain"]),
        .testTarget(
            name: "SecretsTests",
            dependencies: ["Secrets"])
    ]
)
