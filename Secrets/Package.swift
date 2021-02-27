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
        .package(path: "Keychain"),
        .package(name: "Base16", url: "https://github.com/metabolist/base16.git", .upToNextMajor(from: "1.0.0"))
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
