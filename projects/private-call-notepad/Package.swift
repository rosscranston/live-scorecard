// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PrivateCallNotepad",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PrivateCallNotepad", targets: ["PrivateCallNotepad"])
    ],
    targets: [
        .executableTarget(
            name: "PrivateCallNotepad",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "PrivateCallNotepadTests",
            dependencies: ["PrivateCallNotepad"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)

