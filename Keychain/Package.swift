// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Keychain",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Keychain",
            targets: ["Keychain"]),
        .library(
            name: "MockKeychain",
            targets: ["MockKeychain"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Keychain",
            dependencies: []),
        .target(
            name: "MockKeychain",
            dependencies: ["Keychain"]),
        .testTarget(
            name: "KeychainTests",
            dependencies: ["MockKeychain"])
    ]
)
