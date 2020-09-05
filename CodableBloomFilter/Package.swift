// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CodableBloomFilter",
    products: [
        .library(
            name: "CodableBloomFilter",
            targets: ["CodableBloomFilter"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodableBloomFilter",
            dependencies: []),
        .testTarget(
            name: "CodableBloomFilterTests",
            dependencies: ["CodableBloomFilter"])
    ]
)
