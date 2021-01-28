// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ViewModels",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "ViewModels",
            targets: ["ViewModels"]),
        .library(
            name: "PreviewViewModels",
            targets: ["PreviewViewModels"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/CombineExpectations.git", .upToNextMajor(from: "0.7.0")),
        .package(path: "ServiceLayer")
    ],
    targets: [
        .target(
            name: "ViewModels",
            dependencies: ["ServiceLayer"]),
        .target(
            name: "PreviewViewModels",
            dependencies: ["ViewModels", .product(name: "ServiceLayerMocks", package: "ServiceLayer")]),
        .testTarget(
            name: "ViewModelsTests",
            dependencies: ["CombineExpectations", "PreviewViewModels"])
    ]
)
