// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "aries-framework-swift",
    platforms: [
        .macOS(.v11),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AriesFramework",
            targets: ["AriesFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/bhsw/concurrent-ws", exact: "0.5.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit", exact: "0.2.0"),
        .package(url: "https://github.com/keefertaylor/Base58Swift", exact: "2.1.7"),
        .package(url: "https://github.com/thecatalinstan/Criollo", exact: "1.1.0"),
        .package(url: "https://github.com/groue/Semaphore", exact: "0.0.8"),
        .package(url: "https://github.com/beatt83/peerdid-swift", exact: "3.0.3"),
        .package(url: "https://github.com/apple/swift-algorithms", exact: "1.2.0"),
        .package(url: "https://github.com/conanoc/BlueSwift", exact: "1.1.7"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
        .package(url: "https://github.com/LF-Decentralized-Trust-labs/aries-uniffi-wrappers.git", exact: "0.3.1"),
        .package(path: "./packages/indy-besu"),
        .package(path: "./vendors/jsonld"),
        //.package(path: "./packages/anoncreds"),
        //.package(path: "./packages/askar"),
        //.package(path: "./packages/indy-vdr")
    ],
    targets: [
//        .binaryTarget(name: "AnoncredsLocal",
//                      path: "./Sample/libanoncredsuniffi/Frameworks/anoncredsuniffiFFIlocal.xcframework"),
//                      //path: "./Sample/libanoncredsuniffi/Frameworks/anoncreds_uniffiFFI.xcframework.zip"),
        .target(
            name: "AriesFramework",
            dependencies: [
                .product(name: "Anoncreds", package: "aries-uniffi-wrappers"),
                .product(name: "Askar", package: "aries-uniffi-wrappers"),
                .product(name: "IndyVdr", package: "aries-uniffi-wrappers"),
                .product(name: "WebSockets", package: "concurrent-ws"),
                .product(name: "PeerDID", package: "peerdid-swift"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "IndyBesu", package: "indy-besu"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "JSONLD", package: "JSONLD"),
                "CollectionConcurrencyKit",
                "Base58Swift",
                "Semaphore",
                "BlueSwift"
              
            ]),
    
        .testTarget(
            name: "AriesFrameworkTests",
            dependencies: ["AriesFramework", "Criollo",
                .product(name: "Askar", package: "aries-uniffi-wrappers")],
            resources: [
                .copy("resources/local-genesis.txn"),
                .copy("resources/bcovrin-genesis.txn")
            ])
    ]
)
