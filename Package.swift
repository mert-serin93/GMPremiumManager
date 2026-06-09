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
        .package(url: "https://github.com/adaptyteam/AdaptySDK-iOS", exact: "4.0.0-beta.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GMPremiumManager", dependencies: [
                .product(name: "Adapty", package: "AdaptySDK-iOS"),
                .product(name: "AdaptyUI", package: "AdaptySDK-iOS"),
            ]),
        .testTarget(
            name: "GMPremiumManagerTests",
            dependencies: ["GMPremiumManager"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
