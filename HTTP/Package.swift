// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "HTTP",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "HTTP",
            targets: ["HTTP"]),
        .library(
            name: "Stubbing",
            targets: ["Stubbing"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.2.2"))
    ],
    targets: [
        .target(
            name: "HTTP",
            dependencies: ["Alamofire"]),
        .target(
            name: "Stubbing",
            dependencies: ["HTTP"]),
        .testTarget(
            name: "HTTPTests",
            dependencies: ["HTTP"])
    ]
)
