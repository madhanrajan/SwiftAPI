// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SwiftAPI",
    products: [
        .library(name: "SwiftAPI", targets: ["SwiftAPI"]),
        .executable(name: "Example", targets: ["Example"])
    ],
    dependencies: [
        // In a real implementation, you might add SwiftNIO here
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),

    ],
    targets: [
        .target(name: "SwiftAPI", dependencies: [
        
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
        ]),
        .executableTarget(name: "Example", dependencies: ["SwiftAPI"]),
        .testTarget(name: "SwiftAPITests", dependencies: ["SwiftAPI"]),
        
        
    ]
)
