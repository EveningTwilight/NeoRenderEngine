// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RenderEngine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // 完整引擎
        .library(
            name: "RenderEngine",
            targets: ["RenderEngine"]
        ),
        // 核心抽象层 (RHI)
        .library(
            name: "RenderCore",
            targets: ["RenderCore"]
        ),
        // 数学库
        .library(
            name: "RenderMath",
            targets: ["RenderMath"]
        ),
    ],
    targets: [
        // 1. 基础数学库 (无依赖)
        .target(
            name: "RenderMath",
            dependencies: [],
            path: "Sources/RenderMath"
        ),
        
        // 2. 核心抽象层 (依赖 RenderMath)
        .target(
            name: "RenderCore",
            dependencies: ["RenderMath"],
            path: "Sources/RenderCore"
        ),
        
        // 3. Metal 后端实现 (依赖 RenderCore)
        .target(
            name: "RenderMetal",
            dependencies: ["RenderCore", "RenderMath"],
            path: "Sources/RenderMetal"
        ),
        
        // 4. OpenGL ES 2.0 后端实现 (依赖 RenderCore)
        .target(
            name: "RenderGL",
            dependencies: ["RenderCore", "RenderMath"],
            path: "Sources/RenderGL"
        ),
        
        // 5. 引擎高层封装 (聚合后端)
        .target(
            name: "RenderEngine",
            dependencies: [
                "RenderCore",
                "RenderMath",
                "RenderMetal",
                "RenderGL"
            ],
            path: "Sources/RenderEngine"
        ),
        
        // 测试目标
        .testTarget(
            name: "RenderMathTests",
            dependencies: ["RenderMath"]
        ),
        .testTarget(
            name: "RenderCoreTests",
            dependencies: ["RenderCore"]
        ),
    ]
)
