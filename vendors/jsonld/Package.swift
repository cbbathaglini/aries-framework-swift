// swift-tools-version:5.1
// Vendored copy of kasei/swift-jsonld (MIT), target JSONLD only,
// with iOS availability fixes applied.

import PackageDescription

let package = Package(
    name: "JSONLD",
    products: [
        .library(
            name: "JSONLD",
            targets: ["JSONLD"]),
    ],
    targets: [
        .target(name: "JSONLD", dependencies: []),
    ]
)
