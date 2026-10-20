// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "sayx",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "sayx",
            targets: ["sayx"]
        ),
        .library(
            name: "SayXCore",
            targets: ["SayXCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.4")
    ],
    targets: [
        .target(
            name: "SayXCore",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio")
            ],
            path: "Sources/SayXCore"
        ),
        .executableTarget(
            name: "sayx",
            dependencies: ["SayXCore"],
            path: "Sources/SayX"
        ),
        .testTarget(
            name: "SayXUnitTests",
            dependencies: ["SayXCore"],
            path: "Tests/SayXUnitTests"
        ),
        .testTarget(
            name: "SayXIntegrationTests",
            dependencies: ["SayXCore"],
            path: "Tests/SayXIntegrationTests"
        )
    ]
)
