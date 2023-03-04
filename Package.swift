// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spm-check-updates",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "spm-check-updates", targets: ["spm-check-updates"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
        .package(url: "https://github.com/tuist/xcodeproj.git", from: "8.9.0"),
        .package(url: "https://github.com/jkandzi/Progress.swift", from: "0.4.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "spm-check-updates",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "XcodeProj", package: "xcodeproj"),
                .product(name: "Progress", package: "Progress.swift"),
                .product(name: "Rainbow", package: "Rainbow"),
            ]),
        .testTarget(
            name: "spm-check-updatesTests",
            dependencies: ["spm-check-updates"]),
    ]
)
