// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ambassador",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .target(name: "AmbassadorCore"),
        .executableTarget(
            name: "amb",
            dependencies: [
                "AmbassadorCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "AmbassadorApp",
            dependencies: ["AmbassadorCore"],
            resources: [.process("Resources")]
        ),
    ]
)
