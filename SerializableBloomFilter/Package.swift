// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SerializableBloomFilter",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SerializableBloomFilter",
            targets: ["SerializableBloomFilter"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SerializableBloomFilter",
            dependencies: []),
        .testTarget(
            name: "SerializableBloomFilterTests",
            dependencies: ["SerializableBloomFilter"])
    ]
)
