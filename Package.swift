// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenSaver",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenSaver", targets: ["ScreenSaver"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenSaver",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "ScreenSaverTests",
            dependencies: ["ScreenSaver"]
        )
    ]
)
