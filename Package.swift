// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SwiftAPI",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "SwiftAPI", targets: ["SwiftAPI"]),
        .library(name: "SwiftAPICore", targets: ["SwiftAPICore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "SwiftAPI",
            dependencies: ["SwiftAPICore"]
        ),
        // Library target containing your server framework
        .target(
            name: "SwiftAPICore",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ]
        ),
        // Tests
        .testTarget(
            name: "SwiftAPICoreTests",
            dependencies: ["SwiftAPICore"]
        )
    ]
)
