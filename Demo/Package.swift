// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RenderDemo",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "RenderDemo",
            dependencies: [
                .product(name: "RenderEngine", package: "NeoRenderEngine"),
                .product(name: "RenderMath", package: "NeoRenderEngine"),
                .product(name: "RenderCore", package: "NeoRenderEngine")
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
