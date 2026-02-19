// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "IndyBesu",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "IndyBesu",
            targets: ["indy_besu_vdr_uniffi"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "indy_besu_vdr_uniffiFFI",
            path: "Frameworks/indy_besu_vdrFFI.xcframework"
        ),
        .target(
            name: "indy_besu_vdr_uniffi",
            dependencies: ["indy_besu_vdr_uniffiFFI"],
            path: "Sources/indy_besu_uniffi"
        )
    ]
)
