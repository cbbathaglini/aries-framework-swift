// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "IndyVdr",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "IndyVdr",
            targets: ["indy_vdr_uniffi"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "indy_vdr_uniffiFFI",
            path: "Frameworks/indy_vdr_uniffiFFI.xcframework"
        ),
        .target(
            name: "indy_vdr_uniffi",
            dependencies: ["indy_vdr_uniffiFFI"],
            path: "Sources/indy_vdr_uniffi"
        )
    ]
)
