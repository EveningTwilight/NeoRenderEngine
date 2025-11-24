// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RenderDemo",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "../RenderEngine")
    ],
    targets: [
        .executableTarget(
            name: "RenderDemo",
            dependencies: [
                .product(name: "RenderEngine", package: "RenderEngine"),
                .product(name: "RenderMath", package: "RenderEngine"),
                .product(name: "RenderCore", package: "RenderEngine")
            ]
        )
    ]
)
