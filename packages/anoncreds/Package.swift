// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Anoncreds",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Anoncreds",
            targets: ["anoncreds_uniffi"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "anoncredsuniffiFFIlocal",
            path: "Frameworks/anoncreds_uniffiFFI.xcframework"
        ),
        .target(
            name: "anoncreds_uniffi",
            dependencies: ["anoncredsuniffiFFIlocal"],
            path: "Sources/anoncreds_uniffi"
        )
    ]
)
