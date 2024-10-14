// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GMPremiumManager",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GMPremiumManager",
            targets: ["GMPremiumManager"]),
    ],
    dependencies: [
        .package(name: "Adapty", url: "https://github.com/adaptyteam/AdaptySDK-iOS", .upToNextMajor(from: "3.0.3"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GMPremiumManager", dependencies: [
                .product(name: "Adapty", package: "Adapty"),
                .product(name: "AdaptyUI", package: "Adapty"),
            ]),
        .testTarget(
            name: "GMPremiumManagerTests",
            dependencies: ["GMPremiumManager"]
        ),
    ]
)
