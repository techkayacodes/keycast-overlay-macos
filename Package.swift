// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeycastOverlay",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "KeycastOverlayCore", targets: ["KeycastOverlayCore"]),
        .executable(name: "keycast-overlay", targets: ["KeycastOverlay"]),
    ],
    targets: [
        .target(
            name: "KeycastOverlayCore",
            path: "Sources/KeycastOverlayCore"
        ),
        .executableTarget(
            name: "KeycastOverlay",
            dependencies: ["KeycastOverlayCore"],
            path: "Sources/KeycastOverlay"
        ),
        .testTarget(
            name: "KeycastOverlayTests",
            dependencies: ["KeycastOverlayCore"],
            path: "Tests/KeycastOverlayTests"
        ),
    ]
)
