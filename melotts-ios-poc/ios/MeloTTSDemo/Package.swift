// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MeloTTSDemo",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "MeloTTSDemo", targets: ["MeloTTSDemo"])
    ],
    targets: [
        .executableTarget(
            name: "MeloTTSDemo",
            path: "MeloTTSDemo",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
