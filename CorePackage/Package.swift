// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CorePackage",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CorePackage",
            targets: [
                "Architecture",
                "RootTabPresentation",
                "FirstTabParentInteraction",
                "FirstTabParentPresentation",
                "FirstTabChildInteraction",
                "FirstTabChildPresentation",
                "SecondTabInteraction",
                "SecondTabPresentation"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.7.0")
    ],
    targets: [
        .target(
            name: "Architecture",
            dependencies: [
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                .product(name: "CustomDump", package: "swift-custom-dump")
            ]
        ),
        .target(
            name: "RootTabPresentation",
            path: "Sources/RootTab/RootTabPresentation"
        ),
        .target(
            name: "FirstTabParentInteraction",
            dependencies: [
                "Architecture"
            ],
            path: "Sources/FirstTabParent/FirstTabParentInteraction"
        ),
        .target(
            name: "FirstTabParentPresentation",
            dependencies: [
                "Architecture",
                "FirstTabParentInteraction"
            ],
            path: "Sources/FirstTabParent/FirstTabParentPresentation"
        ),
        .target(
            name: "FirstTabChildInteraction",
            dependencies: [
                "Architecture"
            ],
            path: "Sources/FirstTabChild/FirstTabChildInteraction"
        ),
        .target(
            name: "FirstTabChildPresentation",
            dependencies: [
                "Architecture",
                "FirstTabChildInteraction"
            ],
            path: "Sources/FirstTabChild/FirstTabChildPresentation"
        ),
        .target(
            name: "SecondTabInteraction",
            dependencies: [
                "Architecture"
            ],
            path: "Sources/SecondTab/SecondTabInteraction"
        ),
        .target(
            name: "SecondTabPresentation",
            dependencies: [
                "Architecture",
                "SecondTabInteraction"
            ],
            path: "Sources/SecondTab/SecondTabPresentation"
        ),
        .testTarget(
            name: "RootSceneInteractionTests",
            dependencies: [
                "Architecture",
                "FirstTabParentInteraction"
            ]
        ),
        .testTarget(
            name: "RootScenePresentationTests",
            dependencies: [
                "Architecture",
                "FirstTabParentInteraction",
                "FirstTabParentPresentation"
            ]
        )
    ]
)
