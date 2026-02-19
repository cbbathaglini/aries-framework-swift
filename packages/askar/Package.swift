// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Askar",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Askar",
            targets: ["askar_uniffi"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "askar_uniffiFFI",
            path: "Frameworks/askar_uniffiFFI.xcframework"
        ),
        .target(
            name: "askar_uniffi",
            dependencies: ["askar_uniffiFFI"],
            path: "Sources/askar_uniffi"
        )
    ]
)
