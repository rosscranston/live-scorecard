// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LiveCallScorecard",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "LiveScorecard", targets: ["LiveScorecard"])
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite"
        ),
        .executableTarget(
            name: "LiveScorecard",
            dependencies: ["CSQLite"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "LiveScorecardTests",
            dependencies: ["LiveScorecard"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
