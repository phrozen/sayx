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
            targets: ["SayX"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.4")
    ],
    targets: [
        .executableTarget(
            name: "SayX",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio")
            ],
            path: "Sources/SayX"
        )
    ]
)
