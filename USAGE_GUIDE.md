# NeoRenderEngine 使用指南

NeoRenderEngine 是一个基于 Swift 开发的轻量级跨平台渲染引擎，底层支持 Metal (macOS/iOS) 和 OpenGL ES 2.0 (iOS)。

## 1. 快速开始

### 1.1 环境要求
- macOS 10.15+ 或 iOS 13.0+
- Xcode 15.0+ (Swift Tools 5.9)
- Swift 5.9+

### 1.2 安装
在你的 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/EveningTwilight/NeoRenderEngine.git", from: "1.0.0")
]
```

## 2. 基础教程

### 2.1 初始化引擎
首先，创建一个 `GraphicEngine` 实例。建议在 `ViewModel` 或 `ViewController` 中持有它。

```swift
import NeoRenderEngine

// 创建 Metal 后端引擎
let engine = try GraphicEngine(backendType: .metal)

// 开启后处理 (HDR, Bloom, ToneMapping)
engine.isPostProcessingEnabled = true
```

### 2.2 构建场景
场景 (Scene) 是所有渲染对象的容器。

```swift
// 创建场景
let scene = RenderScene()
engine.scene = scene

// 创建相机
let camera = PerspectiveCamera(
    position: Vec3(0, 5, 10), 
    target: Vec3(0, 0, 0), 
    up: Vec3(0, 1, 0)
)
engine.camera = camera
```

### 2.3 添加物体 (Mesh & Material)
引擎提供了 `PrimitiveMesh` 用于快速创建基础几何体。

```swift
// 1. 创建网格 (Mesh)
let cubeMesh = PrimitiveMesh.createCube(device: engine.device, size: 1.0)

// 2. 创建材质 (Material)
// 加载 Shader
let shaderSource = try loadShaderFile("SimpleShader") 
let shader = try engine.resourceManager.createShader(name: "Simple", source: shaderSource)

// 配置管线
var pipelineDesc = PipelineDescriptor(label: "CubePipeline")
pipelineDesc.vertexFunction = "vertex_main"
pipelineDesc.fragmentFunction = "fragment_main"
pipelineDesc.colorPixelFormat = .rgba16Float // 推荐使用 HDR 格式
pipelineDesc.depthPixelFormat = .depth32Float
pipelineDesc.vertexDescriptor = cubeMesh.vertexDescriptor

let pipeline = try engine.resourceManager.createPipeline(name: "CubePipe", descriptor: pipelineDesc, shader: shader)

// 创建材质实例
let material = Material(pipelineState: pipeline)
material.setValue(Vec4(1.0, 0.0, 0.0, 1.0), for: "objectColor") // 红色

// 3. 创建节点并添加到场景
let cubeNode = Node(name: "MyCube")
cubeNode.addComponent(MeshRenderer(mesh: cubeMesh, material: material))
scene.addNode(cubeNode)
```

### 2.4 添加光照
目前支持点光源和方向光（通过 Shader 模拟）。

```swift
let lightNode = Node(name: "MainLight")
lightNode.transform.position = Vec3(5, 10, 5)
let light = LightComponent(type: .point, color: Vec3(1, 1, 1), intensity: 2.0)
lightNode.addComponent(light)
scene.addNode(lightNode)
```

### 2.5 启动渲染
将引擎连接到视图并开始渲染循环。

```swift
// SwiftUI
RenderViewRepresentable(engine: engine)

// 启动
engine.startRendering()
```

## 3. 进阶功能

### 3.1 天空盒 (Skybox)
```swift
let skyboxTexture = try engine.resourceManager.createProceduralSkybox(name: "Stars", size: 512)
let skybox = Skybox(device: engine.device, texture: skyboxTexture)
// ... 配置 Skybox Pipeline ...
engine.sceneRenderer.skybox = skybox
```

### 3.2 阴影 (Shadow Mapping)
```swift
let shadowPass = ShadowMapPass(device: engine.device, width: 2048, height: 2048)
engine.sceneRenderer.shadowMapPass = shadowPass
// 确保材质 Shader 中处理了 shadowMap Uniform
```

## 4. 常见问题
- **Crash on Texture Upload**: 确保非 `.private` 纹理使用了 `.cpuWrite` 标志。
- **Black Screen**: 检查相机位置是否在物体内部，或者 Shader 是否编译失败。
