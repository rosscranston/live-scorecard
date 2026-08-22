// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TaxTerms",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TaxTerms", targets: ["TaxTerms"])
    ],
    targets: [
        .executableTarget(
            name: "TaxTerms",
            resources: [
                .process("SeedResources.json")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "TaxTermsTests",
            dependencies: ["TaxTerms"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
