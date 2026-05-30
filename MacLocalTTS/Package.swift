// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacLocalTTS",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "MacLocalTTS", targets: ["MacLocalTTS"])
    ],
    dependencies: [
        .package(url: "https://github.com/soniqo/speech-swift", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "MacLocalTTS",
            dependencies: [
                .product(name: "CosyVoiceTTS", package: "speech-swift"),
                .product(name: "AudioCommon", package: "speech-swift")
            ]
        )
    ]
)
