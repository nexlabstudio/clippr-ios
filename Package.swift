// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ClipprSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ClipprSDK",
            targets: ["ClipprSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ClipprSDK",
            dependencies: [],
            path: "Sources/ClipprSDK"
        ),
        .testTarget(
            name: "ClipprSDKTests",
            dependencies: ["ClipprSDK"],
            path: "Tests/ClipprSDKTests"
        ),
    ]
)
